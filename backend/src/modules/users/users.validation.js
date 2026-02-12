const { body, param } = require('express-validator');

const validationRules = {
  updateProfile: [
    body('name')
      .optional()
      .trim()
      .isLength({ min: 2, max: 255 })
      .withMessage('Name must be between 2 and 255 characters'),
    body('address')
      .optional()
      .trim(),
    body('phone')
      .optional()
      .trim()
      .isLength({ max: 20 })
      .withMessage('Phone must be less than 20 characters'),
    body('gender')
      .optional()
      .isIn(['male', 'female', 'other'])
      .withMessage('Gender must be male, female, or other'),
    body('profileImageUrl')
      .optional()
      .trim()
      .isURL()
      .withMessage('Profile image must be a valid URL'),
  ],

  getUserById: [
    param('id')
      .isUUID()
      .withMessage('Invalid user ID'),
  ],

  deleteUser: [
    param('id')
      .isUUID()
      .withMessage('Invalid user ID'),
  ],

  assignRoleByEmail: [
    body('email')
      .trim()
      .notEmpty()
      .withMessage('Email is required')
      .isEmail()
      .withMessage('Invalid email address'),
    body('roleId')
      .notEmpty()
      .withMessage('Role ID is required')
      .isUUID()
      .withMessage('Invalid role ID'),
  ],

  assignRoleToMultiple: [
    body('emails')
      .isArray({ min: 1 })
      .withMessage('Emails must be a non-empty array')
      .custom((emails) => {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emails.every((email) => emailRegex.test(email));
      })
      .withMessage('All items must be valid email addresses'),
    body('roleId')
      .notEmpty()
      .withMessage('Role ID is required')
      .isUUID()
      .withMessage('Invalid role ID'),
  ],
};

module.exports = { validationRules };
