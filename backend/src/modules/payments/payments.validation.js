const { body } = require('express-validator');

const createIntentValidation = [
  body('amount').isInt({ min: 100 }).withMessage('Amount must be at least 100 (in smallest currency unit)'),
  body('currency').optional().isString().withMessage('Currency must be a string'),
  body('serviceId').notEmpty().withMessage('Service ID is required'),
  body('appointmentDate').notEmpty().withMessage('Appointment date is required'),
  body('appointmentTime').notEmpty().withMessage('Appointment time is required'),
  body('customerName').trim().notEmpty().withMessage('Customer name is required'),
  body('customerEmail').trim().notEmpty().withMessage('Customer email is required').isEmail().withMessage('Invalid email'),
  body('customerPhone').trim().notEmpty().withMessage('Customer phone is required'),
  body('offerId').optional().isUUID().withMessage('Invalid offer ID'),
];

module.exports = { createIntentValidation };
