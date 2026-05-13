const { body } = require('express-validator');

// Either:
//   • single-service payload: serviceId + appointmentDate + appointmentTime
//   • cart payload: cartItems array (each item carries its own service/date/time/offer/unitPrice)
// The validator below permits both shapes; `serviceId / appointmentDate / appointmentTime`
// are required only when `cartItems` is absent.
const createIntentValidation = [
  body('amount').isInt({ min: 100 }).withMessage('Amount must be at least 100 (in smallest currency unit)'),
  body('currency').optional().isString().withMessage('Currency must be a string'),

  // Cart payload
  body('cartItems').optional().isArray({ min: 1 }).withMessage('cartItems must be a non-empty array'),
  body('cartItems.*.serviceId').optional().isUUID().withMessage('Invalid cart item serviceId'),
  body('cartItems.*.appointmentDate').optional().notEmpty().withMessage('cart item appointmentDate is required'),
  body('cartItems.*.appointmentTime').optional().notEmpty().withMessage('cart item appointmentTime is required'),
  body('cartItems.*.offerId').optional({ values: 'falsy' }).isUUID().withMessage('Invalid cart item offerId'),
  body('cartItems.*.unitPrice').optional().isFloat({ min: 0 }).withMessage('cart item unitPrice must be a number'),

  // Legacy single-service payload (required only if cartItems is not provided)
  body('serviceId').if(body('cartItems').not().exists()).notEmpty().withMessage('Service ID is required'),
  body('appointmentDate').if(body('cartItems').not().exists()).notEmpty().withMessage('Appointment date is required'),
  body('appointmentTime').if(body('cartItems').not().exists()).notEmpty().withMessage('Appointment time is required'),

  body('customerName').trim().notEmpty().withMessage('Customer name is required'),
  body('customerEmail').trim().notEmpty().withMessage('Customer email is required').isEmail().withMessage('Invalid email'),
  body('customerPhone').trim().notEmpty().withMessage('Customer phone is required'),
  body('offerId').optional({ values: 'falsy' }).isUUID().withMessage('Invalid offer ID'),
];

module.exports = { createIntentValidation };
