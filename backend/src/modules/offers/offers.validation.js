const { body, param } = require('express-validator');

const validationRules = {
  createOffer: [
    body('title')
      .trim()
      .notEmpty()
      .withMessage('Offer title is required')
      .isLength({ max: 255 })
      .withMessage('Title must be less than 255 characters'),
    body('description')
      .optional()
      .trim(),
    body('discountPercentage')
      .optional()
      .isFloat({ min: 0, max: 100 })
      .withMessage('Discount percentage must be between 0 and 100'),
    body('discountAmount')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Discount amount must be a positive number'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('startDate')
      .notEmpty()
      .withMessage('Start date is required')
      .isISO8601()
      .withMessage('Invalid start date format. Use YYYY-MM-DD'),
    body('endDate')
      .notEmpty()
      .withMessage('End date is required')
      .isISO8601()
      .withMessage('Invalid end date format. Use YYYY-MM-DD')
      .custom((endDate, { req }) => {
        if (req.body.startDate && new Date(endDate) < new Date(req.body.startDate)) {
          throw new Error('End date must be after start date');
        }
        return true;
      }),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
    body('serviceId')
      .optional()
      .isUUID()
      .withMessage('Invalid service ID'),
    body('courseId')
      .optional()
      .isUUID()
      .withMessage('Invalid course ID'),
  ],

  updateOffer: [
    param('id')
      .isUUID()
      .withMessage('Invalid offer ID'),
    body('title')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Offer title cannot be empty')
      .isLength({ max: 255 })
      .withMessage('Title must be less than 255 characters'),
    body('description')
      .optional()
      .trim(),
    body('discountPercentage')
      .optional()
      .isFloat({ min: 0, max: 100 })
      .withMessage('Discount percentage must be between 0 and 100'),
    body('discountAmount')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Discount amount must be a positive number'),
    body('imageUrl')
      .optional()
      .isURL()
      .withMessage('Invalid image URL'),
    body('startDate')
      .optional()
      .isISO8601()
      .withMessage('Invalid start date format. Use YYYY-MM-DD'),
    body('endDate')
      .optional()
      .isISO8601()
      .withMessage('Invalid end date format. Use YYYY-MM-DD')
      .custom((endDate, { req }) => {
        if (req.body.startDate && new Date(endDate) < new Date(req.body.startDate)) {
          throw new Error('End date must be after start date');
        }
        return true;
      }),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
    body('serviceId')
      .optional()
      .isUUID()
      .withMessage('Invalid service ID'),
    body('courseId')
      .optional()
      .isUUID()
      .withMessage('Invalid course ID'),
  ],

  deleteOffer: [
    param('id')
      .isUUID()
      .withMessage('Invalid offer ID'),
  ],

  getOfferById: [
    param('id')
      .isUUID()
      .withMessage('Invalid offer ID'),
  ],
};

module.exports = { validationRules };
