const { body, param } = require('express-validator');

const validationRules = {
  createCourse: [
    body('title')
      .trim()
      .notEmpty()
      .withMessage('Course title is required')
      .isLength({ max: 255 })
      .withMessage('Title must be less than 255 characters'),
    body('description')
      .optional()
      .trim(),
    body('duration')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('Duration must be less than 100 characters'),
    body('price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
  ],

  updateCourse: [
    param('id')
      .isUUID()
      .withMessage('Invalid course ID'),
    body('title')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Course title cannot be empty')
      .isLength({ max: 255 })
      .withMessage('Title must be less than 255 characters'),
    body('description')
      .optional()
      .trim(),
    body('duration')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('Duration must be less than 100 characters'),
    body('price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Price must be a positive number'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
  ],

  deleteCourse: [
    param('id')
      .isUUID()
      .withMessage('Invalid course ID'),
  ],

  getCourseById: [
    param('id')
      .isUUID()
      .withMessage('Invalid course ID'),
  ],
};

module.exports = { validationRules };
