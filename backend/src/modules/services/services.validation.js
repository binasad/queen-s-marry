const { body, param } = require('express-validator');

const validationRules = {
  createService: [
    body('categoryId')
      .notEmpty()
      .withMessage('Category ID is required')
      .isUUID()
      .withMessage('Invalid category ID'),
    body('name')
      .trim()
      .notEmpty()
      .withMessage('Service name is required'),
    body('description')
      .optional()
      .trim(),
    body('price')
      .notEmpty()
      .withMessage('Price is required')
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('duration')
      .notEmpty()
      .withMessage('Duration is required')
      .isInt({ min: 1 })
      .withMessage('Duration must be a positive integer'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
  ],

  updateService: [
    param('id')
      .isUUID()
      .withMessage('Invalid service ID'),
    body('categoryId')
      .optional()
      .isUUID()
      .withMessage('Invalid category ID'),
    body('name')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Service name cannot be empty'),
    body('price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('duration')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Duration must be a positive integer'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
  ],

  deleteService: [
    param('id')
      .isUUID()
      .withMessage('Invalid service ID'),
  ],

  getServiceById: [
    param('id')
      .isUUID()
      .withMessage('Invalid service ID'),
  ],

  createCategory: [
    body('name')
      .trim()
      .notEmpty()
      .withMessage('Category name is required')
      .isLength({ max: 255 })
      .withMessage('Category name must be less than 255 characters'),
    body('description')
      .optional()
      .trim(),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('displayOrder')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Display order must be a non-negative integer'),
  ],
};

module.exports = { validationRules };
