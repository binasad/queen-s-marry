const { body, param, validationResult } = require('express-validator');

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

const validationRules = {
  createRole: [
    body('name')
      .trim()
      .notEmpty()
      .withMessage('Role name is required')
      .isLength({ max: 100 })
      .withMessage('Role name must be at most 100 characters'),
    body('permissions')
      .optional()
      .isArray()
      .withMessage('Permissions must be an array of slugs'),
    body('permissions.*')
      .optional()
      .isString()
      .withMessage('Permission slug must be string'),
  ],

  updatePermissions: [
    param('id').isUUID().withMessage('Role id must be a valid UUID'),
    body('permissions')
      .optional()
      .isArray()
      .withMessage('Permissions must be an array of slugs'),
    body('permissions.*')
      .optional()
      .isString()
      .withMessage('Permission slug must be string'),
  ],
};

module.exports = { validationRules, handleValidationErrors };
