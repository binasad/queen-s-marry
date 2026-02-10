const { body, param } = require('express-validator');

const validationRules = {
  createExpert: [
    body('name')
      .trim()
      .notEmpty()
      .withMessage('Expert name is required')
      .isLength({ max: 255 })
      .withMessage('Name must be less than 255 characters'),
    body('email')
      .optional()
      .isEmail()
      .withMessage('Invalid email address'),
    body('phone')
      .optional()
      .trim()
      .isLength({ max: 20 })
      .withMessage('Phone must be less than 20 characters'),
    body('specialty')
      .optional()
      .trim(),
    body('bio')
      .optional()
      .trim(),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('serviceIds')
      .optional()
      .isArray()
      .withMessage('Service IDs must be an array'),
  ],

  updateExpert: [
    param('id')
      .isUUID()
      .withMessage('Invalid expert ID'),
    body('name')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Expert name cannot be empty')
      .isLength({ max: 255 })
      .withMessage('Name must be less than 255 characters'),
    body('email')
      .optional()
      .isEmail()
      .withMessage('Invalid email address'),
    body('phone')
      .optional()
      .trim()
      .isLength({ max: 20 })
      .withMessage('Phone must be less than 20 characters'),
    body('specialty')
      .optional()
      .trim(),
    body('bio')
      .optional()
      .trim(),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
    body('serviceIds')
      .optional()
      .isArray()
      .withMessage('Service IDs must be an array'),
  ],

  deleteExpert: [
    param('id')
      .isUUID()
      .withMessage('Invalid expert ID'),
  ],

  getExpertById: [
    param('id')
      .isUUID()
      .withMessage('Invalid expert ID'),
  ],
};

module.exports = { validationRules };
