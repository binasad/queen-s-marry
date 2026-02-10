const { body, validationResult } = require('express-validator');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
    });
  }
  next();
};

// Password validation regex - requires at least: 8 chars, 1 uppercase, 1 number, 1 special char
const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

const validationRules = {
  register: [
    body('name')
      .trim()
      .notEmpty()
      .withMessage('Name is required')
      .isLength({ min: 2, max: 255 })
      .withMessage('Name must be between 2 and 255 characters'),
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
    body('password')
      .notEmpty()
      .withMessage('Password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
    body('phone')
      .optional()
      .trim()
      .matches(/^[0-9+\-() ]{10,20}$/)
      .withMessage('Invalid phone number format'),
    body('gender')
      .optional()
      .isIn(['Male', 'Female', 'Other'])
      .withMessage('Invalid gender value'),
  ],

  login: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
    body('password')
      .notEmpty()
      .withMessage('Password is required'),
  ],

  forgotPassword: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
  ],

  resetPassword: [
    body('token')
      .notEmpty()
      .withMessage('Reset token is required'),
    body('newPassword')
      .notEmpty()
      .withMessage('New password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
  ],

  // For OTP-based reset: email + 6-digit code + strong new password
  resetPasswordOtp: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
    body('code')
      .trim()
      .notEmpty()
      .withMessage('Verification code is required')
      .isLength({ min: 6, max: 6 })
      .withMessage('Verification code must be 6 digits')
      .isNumeric()
      .withMessage('Verification code must be numeric'),
    body('newPassword')
      .notEmpty()
      .withMessage('New password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
  ],

  refreshToken: [
    body('refreshToken')
      .notEmpty()
      .withMessage('Refresh token is required'),
  ],

  verifyEmail: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
    body('code')
      .trim()
      .notEmpty()
      .withMessage('Verification code is required')
      .isLength({ min: 6, max: 6 })
      .withMessage('Verification code must be 6 digits')
      .isNumeric()
      .withMessage('Verification code must be numeric'),
  ],

  changePassword: [
    body('currentPassword')
      .notEmpty()
      .withMessage('Current password is required'),
    body('newPassword')
      .notEmpty()
      .withMessage('New password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
  ],

  // For OTP-based change password: 6-digit code + strong new password
  changePasswordOtp: [
    body('code')
      .trim()
      .notEmpty()
      .withMessage('Verification code is required')
      .isLength({ min: 6, max: 6 })
      .withMessage('Verification code must be 6 digits')
      .isNumeric()
      .withMessage('Verification code must be numeric'),
    body('newPassword')
      .notEmpty()
      .withMessage('New password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
  ],

  // Add this to your validationRules object in auth.validation.js
  sendChangePasswordOtp: [
    // If you expect the email in the body
    body('email')
      .optional() // Optional if you're pulling from req.user.id in the controller
      .isEmail()
      .withMessage('Invalid email format'),
  ],

  // Password setup for role assignment
  setPassword: [
    body('token')
      .notEmpty()
      .withMessage('Setup token is required'),
    body('password')
      .notEmpty()
      .withMessage('Password is required')
      .matches(passwordRegex)
      .withMessage('Password must be 8+ characters with uppercase, number, and special character'),
  ],

  // Minimal validation for resendVerification (expects email)
  resendVerification: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email format')
      .normalizeEmail(),
  ],
};

module.exports = {
  validationRules,
  handleValidationErrors,
};
