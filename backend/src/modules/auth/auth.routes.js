const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { validationRules, handleValidationErrors } = require('./auth.validation');

console.log('--- 🛡️ Controller Method Check ---');
console.log('Register:', typeof authController.register);
console.log('Login:', typeof authController.login);
console.log('Verify Email:', typeof authController.verifyEmail);
console.log('Change Pass OTP (New Name):', typeof authController.changePasswordWithOtp); // Should show function
console.log('---------------------------------');

/**
 * Premium Route Helper
 * Binds the controller methods to the controller instance 
 * to ensure 'this' context is preserved.
 */
const bind = (method) => method.bind(authController);

// --- Public Authentication Routes ---

router.post('/register', 
    validationRules.register, 
    handleValidationErrors, 
    bind(authController.register)
);

router.post('/login', 
    validationRules.login, 
    handleValidationErrors, 
    bind(authController.login)
);

router.post('/guest', 
    bind(authController.guestLogin)
);

router.post('/google',
    bind(authController.googleLogin)
);

router.post('/verify-email', 
    validationRules.verifyEmail, 
    handleValidationErrors, 
    bind(authController.verifyEmail)
);

router.post('/resend-verification', 
    validationRules.resendVerification, 
    handleValidationErrors, 
    bind(authController.resendVerification)
);

// --- Password Recovery & Token Management ---

router.post('/forgot-password', 
    validationRules.forgotPassword, 
    handleValidationErrors, 
    bind(authController.forgotPassword)
);

router.post('/reset-password', 
    validationRules.resetPassword, 
    handleValidationErrors, 
    bind(authController.resetPassword)
);

router.post('/refresh-token', 
    validationRules.refreshToken,
    handleValidationErrors,
    bind(authController.refreshToken)
);

// --- Role-Based Setup Routes ---

router.get('/setup-password/:token', 
    bind(authController.verifySetupToken)
);

router.post('/set-password', 
    validationRules.setPassword, 
    handleValidationErrors, 
    bind(authController.setPassword)
);

// --- Authenticated User Routes (Requires Token) ---

router.post('/change-password', 
    auth, 
    validationRules.changePassword, 
    handleValidationErrors, 
    bind(authController.changePassword)
);

router.post('/send-change-password-otp', 
    auth, // Added auth middleware here as it should be protected
    validationRules.sendChangePasswordOtp, 
    handleValidationErrors, 
    bind(authController.sendChangePasswordOtp)
);

// Correct name matching your AuthController class
// Replace your bind helper with this or just use inline:
router.post('/change-password-otp', auth, (req, res) => authController.changePasswordWithOtp(req, res));

module.exports = router;