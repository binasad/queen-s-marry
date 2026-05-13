const express = require('express');
const router = express.Router();
const jazzcashController = require('./jazzcash.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { body } = require('express-validator');
const { handleValidationErrors } = require('../auth/auth.validation');

// Accepts either:
//   • legacy single-service payload (serviceId + appointmentDate + appointmentTime), or
//   • cart payload (cartItems array, each item carries its own service/date/time).
const initiateValidation = [
  body('amount').isInt({ min: 1 }).withMessage('Amount is required (in PKR)'),

  // Cart payload
  body('cartItems').optional().isArray({ min: 1 }).withMessage('cartItems must be a non-empty array'),
  body('cartItems.*.serviceId').optional().isUUID().withMessage('Invalid cart item serviceId'),
  body('cartItems.*.appointmentDate').optional().notEmpty().withMessage('cart item appointmentDate is required'),
  body('cartItems.*.appointmentTime').optional().notEmpty().withMessage('cart item appointmentTime is required'),
  body('cartItems.*.offerId').optional({ values: 'falsy' }).isUUID().withMessage('Invalid cart item offerId'),
  body('cartItems.*.unitPrice').optional().isFloat({ min: 0 }).withMessage('cart item unitPrice must be a number'),

  // Legacy single-service (required only when cartItems is absent)
  body('serviceId').if(body('cartItems').not().exists()).notEmpty().withMessage('Service ID is required'),
  body('appointmentDate').if(body('cartItems').not().exists()).notEmpty().withMessage('Appointment date is required'),
  body('appointmentTime').if(body('cartItems').not().exists()).notEmpty().withMessage('Appointment time is required'),

  body('customerName').trim().notEmpty().withMessage('Customer name is required'),
  body('customerEmail').trim().notEmpty().isEmail().withMessage('Valid email is required'),
  body('customerPhone').trim().notEmpty().withMessage('Customer phone is required'),
  body('offerId').optional({ values: 'falsy' }).isUUID().withMessage('Invalid offer ID'),
  body('paymentMethod').optional().isIn(['wallet', 'card']).withMessage('paymentMethod must be wallet or card'),
  body('returnUrl').optional().isURL({ require_tld: false }).withMessage('Invalid returnUrl'),
];

router.post('/initiate', auth, initiateValidation, handleValidationErrors, jazzcashController.initiatePayment);
router.post('/return', jazzcashController.handleReturn);
router.get('/return', jazzcashController.handleReturn);
router.post('/notify', jazzcashController.handleServerNotification);
router.get('/status/:txnRefNo', auth, jazzcashController.getTransactionStatus);

module.exports = router;
