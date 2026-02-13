  // (All controller methods are now inside the AuthController class below)
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const { query } = require('../../config/db');
const { hashPassword, comparePassword } = require('../../utils/password');
const { generateTokens, verifyRefreshToken } = require('../../utils/jwt');
const emailService = require('./auth.service.email');
const env = require('../../config/env');

const DEFAULT_ROLE = 'User';
const CUSTOMER_ROLE = 'Customer'; // For mobile app Google sign-in

function getFirebaseAdmin() {
  try {
    const admin = require('firebase-admin');
    if (admin.apps.length === 0) {
      let serviceAccount = null;
      // 1. Try env var (Docker, GitHub Actions, etc.)
      const envJson = process.env.FIREBASE_ADMIN_SDK_JSON || process.env.FIREBASE_CREDENTIALS_JSON;
      if (envJson) {
        try {
          serviceAccount = JSON.parse(envJson);
        } catch (_) {
          console.error('Firebase Admin: Invalid FIREBASE_ADMIN_SDK_JSON JSON');
          return null;
        }
      }
      // 2. Fall back to file
      if (!serviceAccount) {
        const credPath = path.join(process.cwd(), 'firebase-admin-sdk.json');
        if (fs.existsSync(credPath)) {
          serviceAccount = require(credPath);
        }
      }
      if (serviceAccount) {
        admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      }
    }
    return admin.apps.length > 0 ? admin : null;
  } catch (err) {
    console.error('Firebase Admin init error:', err.message);
    return null;
  }
}

// Generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

const getRoleIdByName = async (roleName) => {
  const existing = await query('SELECT id FROM roles WHERE name = $1 LIMIT 1', [roleName]);
  if (existing.rows.length > 0) return existing.rows[0].id;

  const created = await query(
    'INSERT INTO roles (name, is_system_role) VALUES ($1, $2) RETURNING id',
    [roleName, roleName.toLowerCase() === 'owner' || roleName.toLowerCase() === 'admin']
  );
  return created.rows[0].id;
};

const getUserWithRole = async (userId) => {
  const result = await query(
    `SELECT
       u.id,
       u.name,
       u.email,
       u.profile_image_url,
       u.role_id,
       r.name AS role_name,
       COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
     FROM users u
     LEFT JOIN roles r ON u.role_id = r.id
     LEFT JOIN role_permissions rp ON rp.role_id = r.id
     LEFT JOIN permissions p ON p.id = rp.permission_id
     WHERE u.id = $1
     GROUP BY u.id, r.id`,
    [userId]
  );
  return result.rows[0];
};

class AuthController {
  // Email verification by code
  async verifyEmail(req, res) {
    try {
      const { email, code } = req.body;
      if (!email || !code) {
        return res.status(400).json({ success: false, message: 'Email and code are required.' });
      }

      // Find user by email
      const userResult = await query('SELECT id, verification_code, verification_code_expires_at, email_verified FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found.' });
      }
      const user = userResult.rows[0];

      if (user.email_verified) {
        return res.json({ success: true, message: 'Email already verified.' });
      }

      // Check code and expiry
      if (!user.verification_code || user.verification_code !== code) {
        return res.status(400).json({ success: false, message: 'Invalid verification code.' });
      }
      if (user.verification_code_expires_at && new Date(user.verification_code_expires_at) < new Date()) {
        return res.status(400).json({ success: false, message: 'Verification code expired.' });
      }

      // Mark email as verified and clear code
      await query('UPDATE users SET email_verified = TRUE, verification_code = NULL, verification_code_expires_at = NULL WHERE id = $1', [user.id]);

      return res.json({ success: true, message: 'Email verified successfully.' });
    } catch (error) {
      console.error('Email verification error:', error);
      res.status(500).json({ success: false, message: 'Failed to verify email.' });
    }
  }
  // Guest login - session-only, no database storage (privacy-first)
  async guestLogin(req, res) {
    try {
      console.log('👤 Guest login request received');

      const sessionId = crypto.randomUUID();
      const tokens = generateTokens({ sessionId, isGuest: true });

      const syntheticUser = {
        id: sessionId,
        name: 'Guest',
        email: null,
        isGuest: true,
        role: {
          id: null,
          name: 'Guest',
          permissions: [],
        },
        profileImage: null,
      };

      console.log('✅ Guest login successful (session-only, no DB):', sessionId);

      res.json({
        success: true,
        message: 'Guest login successful',
        data: {
          user: syntheticUser,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        },
      });
    } catch (error) {
      console.error('Guest login error:', error);
      res.status(500).json({
        success: false,
        message: 'Guest login failed. Please try again.',
      });
    }
  }

  // Google Sign-In - verify idToken and create/find user
  async googleLogin(req, res) {
    try {
      const { idToken } = req.body;
      if (!idToken) {
        return res.status(400).json({
          success: false,
          message: 'Google idToken is required.',
        });
      }

      const admin = getFirebaseAdmin();
      if (!admin) {
        console.error('Google login: Firebase Admin not initialized. Add firebase-admin-sdk.json or FIREBASE_ADMIN_SDK_JSON env.');
        return res.status(503).json({
          success: false,
          message: 'Google sign-in is not configured. Contact support.',
        });
      }

      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (fbErr) {
        console.error('Google login: verifyIdToken failed:', fbErr.code || fbErr.message, fbErr.message);
        const msg = fbErr.code === 'auth/id-token-expired'
          ? 'Google sign-in expired. Please try again.'
          : fbErr.code === 'auth/argument-error'
            ? 'Invalid Google token. Ensure SHA-1 is added to Firebase.'
            : 'Google token verification failed.';
        return res.status(401).json({ success: false, message: msg });
      }
      const { uid, email, name, picture } = decodedToken;

      if (!email) {
        return res.status(400).json({
          success: false,
          message: 'Google account must have an email.',
        });
      }

      const existingUser = await query(
        'SELECT id FROM users WHERE email = $1',
        [email]
      );

      let userId;
      let userWithRole;

      if (existingUser.rows.length > 0) {
        userId = existingUser.rows[0].id;
        userWithRole = await getUserWithRole(userId);
      } else {
        const roleId = await getRoleIdByName(CUSTOMER_ROLE);
        const newUserId = crypto.randomUUID();
        const passwordPlaceholder = crypto.createHash('sha256').update(uid + email).digest('hex');

        await query(
          `INSERT INTO users (id, name, email, password_hash, role_id, email_verified, profile_image_url)
           VALUES ($1, $2, $3, $4, $5, TRUE, $6)
           RETURNING id`,
          [newUserId, name || email.split('@')[0], email, passwordPlaceholder, roleId, picture || null]
        );
        userId = newUserId;
        userWithRole = await getUserWithRole(userId);
      }

      const tokens = generateTokens({ id: userId });

      console.log('✅ Google login successful for:', email);

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: userWithRole.id,
            name: userWithRole.name,
            email: userWithRole.email,
            role: {
              id: userWithRole.role_id,
              name: userWithRole.role_name,
              permissions: userWithRole.permissions,
            },
            profileImage: userWithRole.profile_image_url,
          },
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        },
      });
    } catch (error) {
      console.error('Google login error:', error?.code || error?.message, error?.stack);
      const msg = error?.code === 'auth/id-token-expired'
        ? 'Google sign-in expired. Please try again.'
        : env.isDevelopment && error?.message
          ? `Google login failed: ${error.message}`
          : 'Google sign-in failed. Please try again.';
      res.status(500).json({ success: false, message: msg });
    }
  }

  // Register new user
  async register(req, res) {
    try {
      const startAll = Date.now();
      console.log('📝 Registration request received');
      console.log('   Email:', req.body.email);
      console.log('   Name:', req.body.name);
      const { name, email, password, address, phone, gender } = req.body;

      // Step 1: Check if email already exists in users table
      const t1 = Date.now();
      const existingUser = await query('SELECT id FROM users WHERE email = $1', [email]);
      const t2 = Date.now();
      console.log(`[TIMER] Check existing user: ${t2 - t1}ms`);
      if (existingUser.rows.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'This email is already registered. Please login instead.',
        });
      }

      // Step 2: Check if email already has pending registration
      const t3 = Date.now();
      const existingPending = await query('SELECT id FROM pending_registrations WHERE email = $1', [email]);
      const t4 = Date.now();
      console.log(`[TIMER] Check pending registration: ${t4 - t3}ms`);
      if (existingPending.rows.length > 0) {
        // Delete old pending registration
        const t5 = Date.now();
        await query('DELETE FROM pending_registrations WHERE email = $1', [email]);
        const t6 = Date.now();
        console.log(`[TIMER] Delete old pending registration: ${t6 - t5}ms`);
      }

      // Step 3: Prepare registration data
      const t7 = Date.now();
      const roleId = await getRoleIdByName(DEFAULT_ROLE);
      const passwordHash = await hashPassword(password);
      const verificationCode = generateOTP();
      const codeExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
      const t8 = Date.now();
      console.log(`[TIMER] Prepare registration data: ${t8 - t7}ms`);

      // Step 4: Store in pending_registrations table
      const t9 = Date.now();
      await query(
        `INSERT INTO pending_registrations (name, email, password_hash, address, phone, gender, verification_code, verification_code_expires_at, role_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [name, email, passwordHash, address, phone, gender, verificationCode, codeExpiresAt, roleId]
      );
      const t10 = Date.now();
      console.log(`[TIMER] Insert pending registration: ${t10 - t9}ms`);

      // Step 5: Send verification email
      const t11 = Date.now();
      try {
        await emailService.sendVerificationEmail(email, verificationCode, name);
      } catch (emailError) {
        console.warn('Warning: Email verification failed, but registration pending. Email error:', emailError.message);
        if (env.isProduction) throw emailError; // Fail in production, continue in dev
      }
      const t12 = Date.now();
      console.log(`[TIMER] Send verification email: ${t12 - t11}ms`);

      const total = Date.now() - startAll;
      console.log(`[TIMER] Total registration time: ${total}ms`);

      res.status(201).json({
        success: true,
        message: 'Registration successful! Please check your email for the verification code.',
        data: {
          email: email,
        },
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Registration failed. Please try again.',
      });
    }
  }

  async login(req, res) {
    try {
      console.log('🔐 Login request received');
      console.log('   Email:', req.body.email);
      
      const { email, password } = req.body;

      const result = await query(
        `SELECT id, name, email, password_hash, role_id, email_verified,
                failed_login_attempts, lockout_until, profile_image_url
         FROM users WHERE email = $1`,
        [email]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password.',
        });
      }

      const user = result.rows[0];

      if (user.lockout_until && new Date(user.lockout_until) > new Date()) {
        const remainingTime = Math.ceil((new Date(user.lockout_until) - new Date()) / 1000);
        return res.status(429).json({
          success: false,
          message: `Too many failed attempts. Please try again in ${remainingTime} seconds.`,
          lockoutRemaining: remainingTime,
        });
      }

      const isMatch = await comparePassword(password, user.password_hash);

      if (!isMatch) {
        const newAttempts = (user.failed_login_attempts || 0) + 1;
        let lockoutUntil = null;

        if (newAttempts >= 3) {
          lockoutUntil = new Date(Date.now() + 30 * 1000);
        }

        await query(
          'UPDATE users SET failed_login_attempts = $1, lockout_until = $2 WHERE id = $3',
          [newAttempts, lockoutUntil, user.id]
        );

        return res.status(401).json({
          success: false,
          message: 'Invalid email or password.',
          attemptsRemaining: Math.max(0, 3 - newAttempts),
        });
      }

      if (!user.email_verified) {
        return res.status(403).json({
          success: false,
          message: 'Please verify your email before logging in.',
          requiresVerification: true,
        });
      }

      await query(
        'UPDATE users SET failed_login_attempts = 0, lockout_until = NULL, last_login = CURRENT_TIMESTAMP WHERE id = $1',
        [user.id]
      );

      const tokens = generateTokens({ id: user.id });
      const userWithRole = await getUserWithRole(user.id);

      console.log('✅ Login successful for:', email);
      console.log('   User ID:', userWithRole.id);
      console.log('   Role:', userWithRole.role_name);

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: userWithRole.id,
            name: userWithRole.name,
            email: userWithRole.email,
            role: {
              id: userWithRole.role_id,
              name: userWithRole.role_name,
              permissions: userWithRole.permissions,
            },
            profileImage: userWithRole.profile_image_url,
          },
          ...tokens,
        },
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Login failed. Please try again.',
      });
    }
  }

  // Verify setup token
  async verifySetupToken(req, res) {
    try {
      const { token } = req.params;

      console.log('\n🔍 [Controller] INCOMING TOKEN CHECK:');
      console.log('   1. URL Param Token:', token ? token.substring(0, 8) + '...' : 'MISSING');
      console.log('   2. Token Length:', token ? token.length : 0);
      console.log('   3. Token Type:', typeof token);
      console.log('   4. Full token:', token);

      if (!token) {
        console.error('❌ [Controller] No token in params');
        return res.status(400).json({
          success: false,
          message: 'Token is required',
        });
      }

      const emailService = require('./auth.service.email');
      console.log('   Calling verifySetupToken...');
      const result = await emailService.emailService.verifySetupToken(token);

      console.log('   [Controller] Verification result received:');
      console.log('      - valid:', result.valid);
      console.log('      - message:', result.message);
      console.log('      - email:', result.email);
      console.log('      - result object:', JSON.stringify(result));

      if (!result || !result.valid) {
        console.error('❌ [Controller] Token validation failed');
        console.error('   Result:', result);
        return res.status(400).json({
          success: false,
          message: result?.message || 'Invalid token',
        });
      }

      console.log('✅ [Controller] Sending success response');
      res.json({
        success: true,
        message: 'Token is valid',
        data: { email: result.email },
      });
    } catch (error) {
      console.error('❌ [Controller] Verify setup token error:', error);
      console.error('   Error stack:', error.stack);
      res.status(500).json({
        success: false,
        message: 'Failed to verify token.',
      });
    }
  }

  // Set password for new users (from role assignment)
  async setPassword(req, res) {
    try {
      const { token, password } = req.body;

      const emailService = require('./auth.service.email');
      const result = await emailService.emailService.verifySetupToken(token);

      if (!result.valid) {
        return res.status(400).json({
          success: false,
          message: result.message,
        });
      }

      // Hash password
      const passwordHash = await hashPassword(password);

      // Update user password (allow updating even if password exists, for role updates)
      const updateResult = await query(
        'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id, name',
        [passwordHash, result.email]
      );

      if (updateResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      // Mark token as used
      await emailService.emailService.markTokenAsUsed(token);

      const user = updateResult.rows[0];

      res.json({
        success: true,
        message: 'Password set successfully. You can now log in to the admin panel.',
        data: {
          email: result.email,
          name: user.name,
          redirectTo: '/login' // Redirect to admin login
        }
      });
    } catch (error) {
      console.error('Set password error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to set password.',
      });
    }
  }

  // Set password for new users (from role assignment)
  async setPassword(req, res) {
    try {
      const { token, password } = req.body;

      const emailService = require('./auth.service.email');
      const result = await emailService.emailService.verifySetupToken(token);

      if (!result.valid) {
        return res.status(400).json({
          success: false,
          message: result.message,
        });
      }

      // Hash password
      const passwordHash = await require('../../utils/password').hashPassword(password);

      // Update user password (allow updating even if password exists, for role updates)
      const { query } = require('../../config/db');
      const updateResult = await query(
        'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id, name',
        [passwordHash, result.email]
      );

      if (updateResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      // Mark token as used
      await emailService.emailService.markTokenAsUsed(token);

      const user = updateResult.rows[0];

      res.json({
        success: true,
        message: 'Password set successfully. You can now log in to the admin panel.',
        data: {
          email: result.email,
          name: user.name,
          redirectTo: '/login' // Redirect to admin login
        }
      });
    } catch (error) {
      console.error('Set password error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to set password.',
      });
    }
  }

  // Verify email with OTP
  async verifyEmail(req, res) {
    try {
      const { email, code } = req.body;

      // Find pending registration with this email and code
      const result = await query(
        `SELECT id, name, email, password_hash, address, phone, gender, role_id, verification_code_expires_at 
         FROM pending_registrations 
         WHERE email = $1 AND verification_code = $2`,
        [email, code]
      );

      if (result.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid verification code.',
        });
      }

      const pendingUser = result.rows[0];

      // Check if expired
      if (new Date() > new Date(pendingUser.verification_code_expires_at)) {
        return res.status(400).json({
          success: false,
          message: 'Verification code has expired. Please register again.',
        });
      }

      // Create the actual user in users table
      const newUserResult = await query(
        `INSERT INTO users (name, email, password_hash, address, phone, gender, role_id, email_verified)
         VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
         RETURNING id`,
        [pendingUser.name, pendingUser.email, pendingUser.password_hash, pendingUser.address, pendingUser.phone, pendingUser.gender, pendingUser.role_id]
      );

      // Delete pending registration
      await query('DELETE FROM pending_registrations WHERE id = $1', [pendingUser.id]);

      // Get user with role
      const user = await getUserWithRole(newUserResult.rows[0].id);

      res.json({
        success: true,
        message: 'Email verified successfully! You can now login.',
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: {
              id: user.role_id,
              name: user.role_name,
              permissions: user.permissions,
            },
          },
        },
      });
    } catch (error) {
      console.error('Email verification error:', error);
      res.status(500).json({
        success: false,
        message: 'Verification failed. Please try again.',
      });
    }
  }

  // Resend verification email
  async resendVerification(req, res) {
    try {
      const startAll = Date.now();
      const { email } = req.body;

      // Step 1: Check pending registrations
      const t1 = Date.now();
      const pendingResult = await query(
        'SELECT id, name FROM pending_registrations WHERE email = $1',
        [email]
      );
      const t2 = Date.now();
      console.log(`[TIMER] Check pending registrations: ${t2 - t1}ms`);

      if (pendingResult.rows.length > 0) {
        const pending = pendingResult.rows[0];

        // Step 2: Generate and update OTP
        const t3 = Date.now();
        const verificationCode = generateOTP();
        const codeExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
        await query(
          'UPDATE pending_registrations SET verification_code = $1, verification_code_expires_at = $2 WHERE id = $3',
          [verificationCode, codeExpiresAt, pending.id]
        );
        const t4 = Date.now();
        console.log(`[TIMER] Update OTP in pending_registrations: ${t4 - t3}ms`);

        // Step 3: Send verification email
        const t5 = Date.now();
        try {
          await emailService.sendVerificationEmail(email, verificationCode, pending.name);
        } catch (emailError) {
          console.error('Error sending verification email (resend):', emailError);
          throw emailError;
        }
        const t6 = Date.now();
        console.log(`[TIMER] Send verification email: ${t6 - t5}ms`);

        const total = Date.now() - startAll;
        console.log(`[TIMER] Total resendVerification time: ${total}ms`);

        return res.json({
          success: true,
          message: 'Verification code sent successfully.',
        });
      }

      // Step 4: Check if user already verified
      const t7 = Date.now();
      const userResult = await query(
        'SELECT id, name, email_verified FROM users WHERE email = $1',
        [email]
      );
      const t8 = Date.now();
      console.log(`[TIMER] Check users table: ${t8 - t7}ms`);

      // Generic response to prevent email enumeration
      const genericMessage = 'If the email exists, a verification code has been sent.';

      if (userResult.rows.length === 0) {
        const total = Date.now() - startAll;
        console.log(`[TIMER] Total resendVerification time: ${total}ms`);
        return res.json({
          success: true,
          message: genericMessage,
        });
      }

      const user = userResult.rows[0];

      if (user.email_verified) {
        const total = Date.now() - startAll;
        console.log(`[TIMER] Total resendVerification time: ${total}ms`);
        return res.json({
          success: true,
          message: 'Email is already verified.',
        });
      }

      const total = Date.now() - startAll;
      console.log(`[TIMER] Total resendVerification time: ${total}ms`);
      res.json({
        success: true,
        message: genericMessage,
      });
    } catch (error) {
      console.error('Resend verification error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to send verification code.',
      });
    }
  }

  // Forgot password
  async forgotPassword(req, res) {
    try {
      const { email, client } = req.body;

      const result = await query(
        'SELECT id, name, email FROM users WHERE email = $1',
        [email]
      );

      // Generic response to prevent email enumeration
      const genericMessage = 'If an account exists with this email, a password reset link has been sent.';

      if (result.rows.length === 0) {
        return res.json({
          success: true,
          message: genericMessage,
        });
      }

      const user = result.rows[0];

      // Generate reset token
      const resetToken = crypto.randomBytes(32).toString('hex');
      const resetExpires = new Date(Date.now() + 3600000); // 1 hour

      await query(
        'UPDATE users SET reset_password_token = $1, reset_password_expires = $2 WHERE id = $3',
        [resetToken, resetExpires, user.id]
      );

      // Use admin-web URL when client=admin so link goes to admin panel
      await emailService.sendPasswordResetEmail(email, resetToken, user.name, client === 'admin');

      res.json({
        success: true,
        message: genericMessage,
      });
    } catch (error) {
      console.error('Forgot password error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred. Please try again.',
      });
    }
  }

  // Forgot password via OTP code
  async forgotPasswordOtp(req, res) {
    try {
      const { email } = req.body;

      const result = await query(
        'SELECT id, name, email FROM users WHERE email = $1',
        [email]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No account found for this email.',
        });
      }

      const user = result.rows[0];

      // Generate 6-digit code and set expiry (10 minutes)
      const resetCode = generateOTP();
      const resetExpires = new Date(Date.now() + 10 * 60 * 1000);

      // Reuse existing columns to store code and expiry
      await query(
        'UPDATE users SET reset_password_token = $1, reset_password_expires = $2 WHERE id = $3',
        [resetCode, resetExpires, user.id]
      );

      await emailService.sendPasswordResetCodeEmail(email, resetCode, user.name);

      res.json({
        success: true,
        message: 'Reset code sent to your email.',
      });
    } catch (error) {
      console.error('Forgot password (OTP) error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred. Please try again.',
      });
    }
  }

  // Reset password
  async resetPassword(req, res) {
    try {
      const { token, newPassword } = req.body;

      const result = await query(
        'SELECT id FROM users WHERE reset_password_token = $1 AND reset_password_expires > CURRENT_TIMESTAMP',
        [token]
      );

      if (result.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired reset token.',
        });
      }

      const userId = result.rows[0].id;

      // Hash new password
      const passwordHash = await hashPassword(newPassword);

      await query(
        'UPDATE users SET password_hash = $1, reset_password_token = NULL, reset_password_expires = NULL WHERE id = $2',
        [passwordHash, userId]
      );

      res.json({
        success: true,
        message: 'Password reset successful. You can now login with your new password.',
      });
    } catch (error) {
      console.error('Reset password error:', error);
      res.status(500).json({
        success: false,
        message: 'Password reset failed. Please try again.',
      });
    }
  }

  // Reset password using email + 6-digit code
  async resetPasswordOtp(req, res) {
    try {
      const { email, code, newPassword } = req.body;

      const result = await query(
        'SELECT id FROM users WHERE email = $1 AND reset_password_token = $2 AND reset_password_expires > CURRENT_TIMESTAMP',
        [email, code]
      );

      if (result.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired reset code.',
        });
      }

      const userId = result.rows[0].id;
      const passwordHash = await hashPassword(newPassword);

      await query(
        'UPDATE users SET password_hash = $1, reset_password_token = NULL, reset_password_expires = NULL WHERE id = $2',
        [passwordHash, userId]
      );

      res.json({
        success: true,
        message: 'Password reset successful. You can now login with your new password.',
      });
    } catch (error) {
      console.error('Reset password (OTP) error:', error);
      res.status(500).json({
        success: false,
        message: 'Password reset failed. Please try again.',
      });
    }
  }

  // Refresh access token
  async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;
      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token is required.',
        });
      }

      const decoded = verifyRefreshToken(refreshToken);

      if (decoded.isGuest === true && decoded.sessionId) {
        const tokens = generateTokens({ sessionId: decoded.sessionId, isGuest: true });
        res.json({
          success: true,
          message: 'Token refreshed',
          data: {
            user: {
              id: decoded.sessionId,
              name: 'Guest',
              email: null,
              isGuest: true,
              role: { id: null, name: 'Guest', permissions: [] },
              profileImage: null,
            },
            ...tokens,
          },
        });
        return;
      }

      const userResult = await query('SELECT id FROM users WHERE id = $1', [decoded.id]);

      if (userResult.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token.',
        });
      }

      const tokens = generateTokens({ id: decoded.id });
      const userWithRole = await getUserWithRole(decoded.id);

      res.json({
        success: true,
        message: 'Token refreshed',
        data: {
          user: {
            id: userWithRole.id,
            name: userWithRole.name,
            email: userWithRole.email,
            role: {
              id: userWithRole.role_id,
              name: userWithRole.role_name,
              permissions: userWithRole.permissions,
            },
            profileImage: userWithRole.profile_image_url,
          },
          ...tokens,
        },
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      const status = error.name === 'TokenExpiredError' ? 401 : 400;
      res.status(status).json({
        success: false,
        message: 'Unable to refresh token.',
      });
    }
  }

  // Change password
  async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;

      const result = await query(
        'SELECT password_hash FROM users WHERE id = $1',
        [req.user.id]
      );

      const user = result.rows[0];

      // Verify current password
      const isMatch = await comparePassword(currentPassword, user.password_hash);

      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect.',
        });
      }

      // Hash new password
      const passwordHash = await hashPassword(newPassword);

      await query(
        'UPDATE users SET password_hash = $1 WHERE id = $2',
        [passwordHash, req.user.id]
      );

      res.json({
        success: true,
        message: 'Password changed successfully.',
      });
    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to change password.',
      });
    }
  }

  // Send OTP for change password (user is already authenticated)
  async sendChangePasswordOtp(req, res) {
    try {
      // Get user's email from authenticated user
      const result = await query(
        'SELECT id, name, email FROM users WHERE id = $1',
        [req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      const user = result.rows[0];

      // Generate 6-digit code and set expiry (10 minutes)
      const otpCode = generateOTP();
      const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

      // Store OTP in verification_code columns (reusing for change password)
      await query(
        'UPDATE users SET verification_code = $1, verification_code_expires_at = $2 WHERE id = $3',
        [otpCode, otpExpires, user.id]
      );

      await emailService.sendPasswordResetCodeEmail(user.email, otpCode, user.name);

      res.json({
        success: true,
        message: 'Verification code sent to your email.',
      });
    } catch (error) {
      console.error('Send change password OTP error:', error);
      res.status(500).json({
        success: false,
        message: 'An error occurred. Please try again.',
      });
    }
  }

  // Change password using OTP verification
  async changePasswordWithOtp(req, res) {
    try {
      const { code, newPassword } = req.body;

      // Verify OTP code
      const result = await query(
        `SELECT id, verification_code, verification_code_expires_at 
         FROM users 
         WHERE id = $1 AND verification_code = $2`,
        [req.user.id, code]
      );

      if (result.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid verification code.',
        });
      }

      const user = result.rows[0];

      // Check if code has expired
      if (new Date(user.verification_code_expires_at) < new Date()) {
        return res.status(400).json({
          success: false,
          message: 'Verification code has expired. Please request a new one.',
        });
      }

      // Hash new password
      const passwordHash = await hashPassword(newPassword);

      // Update password and clear OTP
      await query(
        `UPDATE users 
         SET password_hash = $1, verification_code = NULL, verification_code_expires_at = NULL 
         WHERE id = $2`,
        [passwordHash, req.user.id]
      );

      res.json({
        success: true,
        message: 'Password changed successfully.',
      });
    } catch (error) {
      console.error('Change password with OTP error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to change password.',
      });
    }
  }
}

// Duplicate method removed - using the one in the class (line 209)

// Set password for new users (from role assignment)
AuthController.prototype.setPassword = async function(req, res) {
  try {
    const { token, password } = req.body;

    const emailService = require('./auth.service.email');
    const result = await emailService.emailService.verifySetupToken(token);

    if (!result.valid) {
      return res.status(400).json({
        success: false,
        message: result.message,
      });
    }

    // Hash password
    const passwordHash = await require('../../utils/password').hashPassword(password);

    // Update user password (allow updating even if password exists, for role updates)
    const { query } = require('../../config/db');
    const updateResult = await query(
      'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id, name',
      [passwordHash, result.email]
    );

    if (updateResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    // Mark token as used
    emailService.emailService.markTokenAsUsed(token);

    const user = updateResult.rows[0];

    res.json({
      success: true,
      message: 'Password set successfully. You can now log in to the admin panel.',
      data: {
        email: result.email,
        name: user.name,
        redirectTo: '/login' // Redirect to admin login
      }
    });
  } catch (error) {
    console.error('Set password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to set password.',
    });
  }
};

// Create controller instance
const authController = new AuthController();


module.exports = authController;
