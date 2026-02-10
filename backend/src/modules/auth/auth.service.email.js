const nodemailer = require('nodemailer');
const env = require('../../config/env');
const { query } = require('../../config/db');

// Get email configuration with proper fallbacks
const emailHost = env.email?.host || process.env.EMAIL_HOST || process.env.SMTP_HOST || 'smtp.gmail.com';
const emailPort = env.email?.port || parseInt(process.env.EMAIL_PORT || process.env.SMTP_PORT || '465');
const emailSecure = env.email?.secure !== undefined ? env.email.secure : (emailPort === 465);
const emailUser = env.email?.user || process.env.EMAIL_USER || process.env.SMTP_USER;
const emailPassword = env.email?.password || process.env.EMAIL_PASSWORD || process.env.SMTP_PASS || process.env.SMTP_PASSWORD;

// Debug logging (remove in production)
console.log('📧 Email Configuration:');
console.log('  Host:', emailHost);
console.log('  Port:', emailPort);
console.log('  Secure:', emailSecure);
console.log('  User:', emailUser ? `${emailUser.substring(0, 3)}***` : 'MISSING');
console.log('  Password:', emailPassword ? '***SET***' : 'MISSING');

// Create transporter for email functions with optimized settings
const transporter = nodemailer.createTransport({
  host: emailHost,
  port: emailPort,
  secure: emailSecure,
  auth: {
    user: emailUser,
    pass: emailPassword,
  },
  // Optimized timeouts for faster connection
  connectionTimeout: 5000, // 5 seconds to establish connection
  socketTimeout: 5000, // 5 seconds for socket operations
  greetingTimeout: 5000, // 5 seconds for SMTP greeting
  // Connection pooling for better performance
  pool: true,
  maxConnections: 1, // Gmail works better with single connection
  maxMessages: 3, // Close connection after 3 messages
  rateDelta: 1000, // Wait 1 second between messages
  rateLimit: 5, // Max 5 messages per rateDelta
  // Disable debug to reduce overhead
  debug: false,
  logger: false,
  // TLS settings for better performance
  requireTLS: emailPort === 587,
  tls: {
    // In production, set to true for better security
    rejectUnauthorized: process.env.NODE_ENV === 'production' ? true : false,
    minVersion: 'TLSv1.2'
  }
});

// Verify transporter configuration on startup
if (emailUser && emailPassword) {
  transporter.verify(function (error, success) {
    if (error) {
      console.error('❌ Email transporter verification failed:', error.message);
    } else {
      console.log('✅ Email transporter is ready to send emails');
    }
  });
} else {
  console.error('❌ Email credentials are missing! Cannot send emails.');
  console.error('   Required: SMTP_USER and SMTP_PASS (or EMAIL_USER and EMAIL_PASSWORD)');
}

// Token expiry: 24 hours
const TOKEN_EXPIRY_HOURS = 24;

// Generate setup token
function generateSetupToken() {
  return require('crypto').randomBytes(32).toString('hex');
}

// Send welcome email for role assignment
async function sendWelcomeEmail(email, name, isRoleUpdate = false) {
  const setupToken = generateSetupToken();
  const expiryTime = new Date(Date.now() + TOKEN_EXPIRY_HOURS * 60 * 60 * 1000);

  // Store token in database (reuse reset_password_token columns)
  try {
    console.log('💾 Storing setup token for:', email);
    console.log('   Token (first 8 chars):', setupToken.substring(0, 8));
    console.log('   Token length:', setupToken.length);
    console.log('   Expiry:', expiryTime.toISOString());
    
    // First verify user exists
    const userCheck = await query('SELECT id, email FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length === 0) {
      console.error('❌ User does not exist in database:', email);
      throw new Error(`User with email ${email} does not exist in database. Please create the user first.`);
    }
    
    console.log('   User found in database, ID:', userCheck.rows[0].id);
    
    // Store the token
    const updateResult = await query(
      `UPDATE users 
       SET reset_password_token = $1, reset_password_expires = $2 
       WHERE email = $3`,
      [setupToken, expiryTime, email]
    );
    
    console.log('   Update result rowCount:', updateResult.rowCount);
    
    if (updateResult.rowCount === 0) {
      console.error('⚠️ UPDATE query returned 0 rows for:', email);
      throw new Error(`Failed to update token for user ${email}`);
    }
    
    // Verify token was stored correctly
    const verifyResult = await query(
      'SELECT reset_password_token, reset_password_expires FROM users WHERE email = $1',
      [email]
    );
    
    if (verifyResult.rows.length === 0) {
      console.error('❌ Could not verify token storage - user not found after update');
      throw new Error('Failed to verify token storage');
    }
    
    const storedToken = verifyResult.rows[0].reset_password_token;
    const storedExpiry = verifyResult.rows[0].reset_password_expires;
    
    console.log('✅ Setup token stored in database for:', email);
    console.log('   Stored token (first 8 chars):', storedToken ? storedToken.substring(0, 8) : 'NULL');
    console.log('   Stored token length:', storedToken ? storedToken.length : 0);
    console.log('   Stored expiry:', storedExpiry);
    
    if (!storedToken) {
      console.error('❌ Token is NULL in database!');
      throw new Error('Token was not stored correctly - token is NULL');
    }
    
    if (storedToken !== setupToken) {
      console.error('❌ Token mismatch!');
      console.error('   Expected (first 16):', setupToken.substring(0, 16));
      console.error('   Got (first 16):', storedToken.substring(0, 16));
      throw new Error('Token was not stored correctly - token mismatch');
    }
    
    console.log('✅ Token verified and stored correctly');
  } catch (error) {
    console.error('❌ Error storing setup token:', error);
    console.error('   Error message:', error.message);
    console.error('   Error stack:', error.stack);
    throw error;
  }

  const setupLink = `${process.env.ADMIN_WEB_URL || env.adminWebUrl || env.FRONTEND_URL || 'http://localhost:3001'}/set-password?token=${setupToken}`;

  const subject = isRoleUpdate ? 'Your Account Role Has Been Updated' : 'Welcome to Merry Queen Salon!';
  const greeting = isRoleUpdate ? 'Your account role has been updated!' : 'Welcome to Merry Queen Salon!';

  const mailOptions = {
    from: process.env.EMAIL_FROM || env.EMAIL_FROM || 'noreply@salon.com',
    to: email,
    subject: subject,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #FF6CBF; margin: 0;">Merry Queen Salon</h1>
          <p style="color: #666; margin: 5px 0;">Professional Salon Services</p>
        </div>

        <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px; margin-bottom: 20px;">
          <h2 style="color: #333; margin-top: 0;">Hello ${name}!</h2>
          <p style="font-size: 16px; line-height: 1.6; color: #555;">
            ${greeting}
          </p>
          <p style="font-size: 16px; line-height: 1.6; color: #555;">
            ${isRoleUpdate
              ? 'Your account permissions have been updated. You now have access to additional features in our system.'
              : 'You have been granted access to our salon management system. To get started, please set up your password by clicking the button below.'
            }
          </p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="${setupLink}" style="display: inline-block; padding: 15px 30px; background-color: #FF6CBF; color: white; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: bold; box-shadow: 0 4px 6px rgba(255, 108, 191, 0.2);">
            ${isRoleUpdate ? 'Update Your Password' : 'Set Up Your Password'}
          </a>
        </div>

        <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 20px 0;">
          <p style="margin: 0; color: #856404; font-size: 14px;">
            <strong>Security Note:</strong>
            <p>This link will expire in 24 hours. If you didn't expect this email, please contact our support team.</p>
          </p>
        </div>

        <div style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 30px;">
          <p style="text-align: center; color: #666; font-size: 14px;">
            Need help? Contact us at support@merryqueensalon.com<br>
            Visit us at I-8 Markaz, Islamabad
          </p>
        </div>
      </div>
    `,
  };

  // Send email asynchronously (don't block the request)
  // Return immediately - email is sent in background
  const emailStartTime = Date.now();
  console.log('📧 Email queued for sending to:', email);
  console.log('   Start time:', new Date().toISOString());
  
  transporter.sendMail(mailOptions)
    .then((info) => {
      const duration = Date.now() - emailStartTime;
      console.log('✅ Welcome email sent to:', email);
      console.log('   Duration:', duration + 'ms');
      console.log('   Message ID:', info.messageId);
      console.log('   Response:', info.response);
    })
    .catch((error) => {
      const duration = Date.now() - emailStartTime;
      console.error('❌ Error sending welcome email:', error);
      console.error('   Email:', email);
      console.error('   Duration before error:', duration + 'ms');
      console.error('   Error message:', error.message);
      console.error('   Error code:', error.code);
      
      // Clean up token if email fails (async)
      query(
        'UPDATE users SET reset_password_token = NULL, reset_password_expires = NULL WHERE email = $1',
        [email]
      ).catch(err => {
        console.error('   Failed to clean up token:', err);
      });
    });
  
  // Function returns immediately, email sending happens in background
}

// Verify setup token (from database)
async function verifySetupToken(token) {
  try {
    if (!token || token.length < 10) {
      console.log('❌ Invalid token format');
      return { valid: false, message: 'Invalid token format' };
    }
    
    console.log('🔍 Verifying setup token:', token.substring(0, 8) + '...');
    console.log('   Full token length:', token.length);
    
    // First check if token exists at all
    const tokenCheck = await query(
      'SELECT email, reset_password_token, reset_password_expires FROM users WHERE reset_password_token = $1',
      [token]
    );
    
    console.log('   Tokens found with this value:', tokenCheck.rows.length);
    
    if (tokenCheck.rows.length === 0) {
      // Check all tokens in database for debugging
      const allTokens = await query(
        'SELECT email, reset_password_token, reset_password_expires FROM users WHERE reset_password_token IS NOT NULL LIMIT 5'
      );
      console.log('   Total tokens in database:', allTokens.rows.length);
      if (allTokens.rows.length > 0) {
        console.log('   Sample tokens:', allTokens.rows.map(r => ({
          email: r.email,
          token: r.reset_password_token ? r.reset_password_token.substring(0, 8) + '...' : 'NULL',
          expires: r.reset_password_expires
        })));
      }
      
      console.log('❌ Token not found in database');
      return { valid: false, message: 'Invalid token' };
    }
    
    const tokenData = tokenCheck.rows[0];
    console.log('   Token found for email:', tokenData.email);
    console.log('   Token expires at:', tokenData.reset_password_expires);
    console.log('   Current time:', new Date().toISOString());
    
    // Check if expired
    if (new Date(tokenData.reset_password_expires) < new Date()) {
      console.log('❌ Token found but expired');
      return { valid: false, message: 'Token has expired. Please request a new one.' };
    }
    
    console.log('✅ Token valid for email:', tokenData.email);
    return { valid: true, email: tokenData.email };
  } catch (error) {
    console.error('Error verifying setup token:', error);
    console.error('   Error stack:', error.stack);
    return { valid: false, message: 'Error verifying token' };
  }
}

// Mark token as used
async function markTokenAsUsed(token) {
  try {
    await query(
      'UPDATE users SET reset_password_token = NULL, reset_password_expires = NULL WHERE reset_password_token = $1',
      [token]
    );
    console.log('Setup token marked as used and removed from database');
  } catch (error) {
    console.error('Error marking token as used:', error);
  }
}

class EmailService {
  constructor() {
    this.transporter = transporter; // Use the global transporter instance
  }

  async sendVerificationEmail(email, code, name) {
    const mailOptions = {
      from: env.email?.from || env.EMAIL_FROM || 'noreply@salon.com',
      to: email,
      subject: 'Verify Your Email - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; text-align: center; }
            .otp-code { 
              font-size: 36px; 
              font-weight: bold; 
              letter-spacing: 8px; 
              color: #FF6CBF; 
              background: #fff; 
              padding: 20px; 
              border-radius: 8px;
              display: inline-block;
              margin: 20px 0;
              border: 2px dashed #FF6CBF;
            }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; text-align: left; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to Salon App!</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>Thank you for registering! Please use the verification code below to confirm your email address:</p>
              <div class="otp-code">${code}</div>
              <div class="warning">
                <strong>⏰ Important:</strong>
                <p>This code will expire in <strong>10 minutes</strong>. If you didn't create this account, please ignore this email.</p>
              </div>
              <p>Enter this code in the app to complete your registration.</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Verification email sent to:', email);
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw error;
    }
  }

  async sendPasswordResetEmail(email, token, name) {
    const resetUrl = `${env.frontendUrl || env.FRONTEND_URL || 'http://localhost:3001'}/reset-password/${token}`;

    const mailOptions = {
      from: env.email?.from || env.EMAIL_FROM || 'noreply@salon.com',
      to: email,
      subject: 'Reset Your Password - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #FF6CBF; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Password Reset Request</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>We received a request to reset your password for your Salon App account. Click the button below to reset it:</p>
              <div style="text-align: center;">
                <a href="${resetUrl}" class="button">Reset Password</a>
              </div>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break: break-all; color: #666;">${resetUrl}</p>
              <div class="warning">
                <strong>⚠️ Security Notice:</strong>
                <p>This link will expire in 1 hour. If you didn't request this password reset, please ignore this email and your password will remain unchanged.</p>
              </div>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Password reset email sent to:', email);
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw error;
    }
  }

  async sendPasswordResetCodeEmail(email, code, name) {
    const mailOptions = {
      from: env.email?.from || env.EMAIL_FROM || 'noreply@salon.com',
      to: email,
      subject: 'Your Password Reset Code - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; text-align: center; }
            .otp-code { 
              font-size: 36px; 
              font-weight: bold; 
              letter-spacing: 8px; 
              color: #FF6CBF; 
              background: #fff; 
              padding: 20px; 
              border-radius: 8px;
              display: inline-block;
              margin: 20px 0;
              border: 2px dashed #FF6CBF;
            }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; text-align: left; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Password Reset Code</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>Use the verification code below to reset your password:</p>
              <div class="otp-code">${code}</div>
              <div class="warning">
                <strong>⏰ Important:</strong>
                <p>This code will expire in <strong>10 minutes</strong>. If you didn't request a password reset, you can safely ignore this email.</p>
              </div>
              <p>Enter this code in the app along with your new password.</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Password reset code email sent to:', email);
    } catch (error) {
      console.error('Error sending password reset code email:', error);
      throw error;
    }
  }

  async sendAppointmentConfirmation(email, appointmentData) {
    const { customerName, serviceName, date, time, price } = appointmentData;

    const mailOptions = {
      from: env.email?.from || env.EMAIL_FROM || 'noreply@salon.com',
      to: email,
      subject: 'Appointment Confirmation - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .appointment-details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
            .detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✓ Appointment Confirmed</h1>
            </div>
            <div class="content">
              <p>Hi ${customerName},</p>
              <p>Your appointment has been confirmed! We look forward to serving you.</p>
              <div class="appointment-details">
                <h3>Appointment Details:</h3>
                <div class="detail-row">
                  <strong>Service:</strong>
                  <span>${serviceName}</span>
                </div>
                <div class="detail-row">
                  <strong>Date:</strong>
                  <span>${date}</span>
                </div>
                <div class="detail-row">
                  <strong>Time:</strong>
                  <span>${time}</span>
                </div>
                <div class="detail-row">
                  <strong>Price:</strong>
                  <span>$${price}</span>
                </div>
              </div>
              <p>If you need to reschedule or cancel, please contact us at least 24 hours in advance.</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Appointment confirmation email sent to:', email);
    } catch (error) {
      console.error('Error sending appointment confirmation:', error);
      throw error;
    }
  }
}


// Export EmailService instance
const emailServiceInstance = new EmailService();

// Export additional functions for role assignment emails
emailServiceInstance.emailService = {
  sendWelcomeEmail,
  verifySetupToken,
  markTokenAsUsed,
  transporter
};

module.exports = emailServiceInstance;
