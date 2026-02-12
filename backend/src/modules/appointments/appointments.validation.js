const { body, param } = require('express-validator');

const validationRules = {
  createAppointment: [
    body('serviceId')
      .notEmpty()
      .withMessage('Service ID is required')
      .isUUID()
      .withMessage('Invalid service ID'),
    body('customerName')
      .trim()
      .notEmpty()
      .withMessage('Customer name is required'),
    body('customerPhone')
      .trim()
      .notEmpty()
      .withMessage('Customer phone is required')
      .matches(/^[0-9+\-() ]{10,20}$/)
      .withMessage('Invalid phone number format'),
    body('customerEmail')
      .trim()
      .notEmpty()
      .withMessage('Customer email is required')
      .isEmail()
      .withMessage('Invalid email format'),
    body('appointmentDate')
      .notEmpty()
      .withMessage('Appointment date is required')
      .isISO8601()
      .withMessage('Invalid date format'),
    body('appointmentTime')
      .notEmpty()
      .withMessage('Appointment time is required')
      .matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/)
      .withMessage('Invalid time format (HH:MM)'),
    body('payNow')
      .isBoolean()
      .withMessage('payNow must be a boolean'),
    body('paymentMethod')
      .optional()
      .isIn(['online', 'cash', 'card'])
      .withMessage('Invalid payment method'),
    body('expertId')
      .optional()
      .isUUID()
      .withMessage('Invalid expert ID'),
    body('offerId')
      .optional()
      .isUUID()
      .withMessage('Invalid offer ID'),
  ],

  updateAppointmentStatus: [
    param('id')
      .isUUID()
      .withMessage('Invalid appointment ID'),
    body('status')
      .notEmpty()
      .withMessage('Status is required')
      .isIn(['confirmed', 'reserved', 'completed', 'cancelled'])
      .withMessage('Invalid status value'),
    body('cancelReason')
      .optional()
      .trim(),
  ],

  markAsPaid: [
    param('id')
      .isUUID()
      .withMessage('Invalid appointment ID'),
    body('paymentMethod')
      .notEmpty()
      .withMessage('Payment method is required')
      .isIn(['online', 'cash', 'card'])
      .withMessage('Invalid payment method'),
  ],

  cancelAppointment: [
    param('id')
      .isUUID()
      .withMessage('Invalid appointment ID'),
    body('reason')
      .optional()
      .trim(),
  ],
};

module.exports = { validationRules };
