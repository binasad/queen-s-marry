const { body, param } = require('express-validator');

const validationRules = {
  addFavorite: [
    body('itemType')
      .notEmpty()
      .withMessage('itemType is required')
      .isIn(['service', 'course'])
      .withMessage('itemType must be "service" or "course"'),
    body('itemId')
      .notEmpty()
      .withMessage('itemId is required')
      .isUUID()
      .withMessage('Invalid itemId (must be UUID)'),
  ],

  removeFavorite: [
    param('itemType')
      .isIn(['service', 'course'])
      .withMessage('itemType must be "service" or "course"'),
    param('itemId')
      .isUUID()
      .withMessage('Invalid itemId (must be UUID)'),
  ],

  checkFavorite: [
    param('itemType')
      .isIn(['service', 'course'])
      .withMessage('itemType must be "service" or "course"'),
    param('itemId')
      .isUUID()
      .withMessage('Invalid itemId (must be UUID)'),
  ],
};

module.exports = { validationRules };
