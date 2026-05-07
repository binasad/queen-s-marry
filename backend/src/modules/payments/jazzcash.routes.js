const express = require('express');
const router = express.Router();
const jazzcashController = require('./jazzcash.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { body } = require('express-validator');
const { handleValidationErrors } = require('../auth/auth.validation');

const initiateValidation = [
  body('amount').isInt({ min: 1 }).withMessage('Amount is required (in PKR)'),
  body('serviceId').notEmpty().withMessage('Service ID is required'),
  body('appointmentDate').notEmpty().withMessage('Appointment date is required'),
  body('appointmentTime').notEmpty().withMessage('Appointment time is required'),
  body('customerName').trim().notEmpty().withMessage('Customer name is required'),
  body('customerEmail').trim().notEmpty().isEmail().withMessage('Valid email is required'),
  body('customerPhone').trim().notEmpty().withMessage('Customer phone is required'),
  body('offerId').optional().isUUID().withMessage('Invalid offer ID'),
  body('paymentMethod').optional().isIn(['wallet', 'card']).withMessage('paymentMethod must be wallet or card'),
  body('returnUrl').optional().isURL({ require_tld: false }).withMessage('Invalid returnUrl'),
];

router.post('/initiate', auth, initiateValidation, handleValidationErrors, jazzcashController.initiatePayment);
router.post('/return', jazzcashController.handleReturn);
router.get('/return', jazzcashController.handleReturn);
router.post('/notify', jazzcashController.handleServerNotification);
router.get('/status/:txnRefNo', auth, jazzcashController.getTransactionStatus);

module.exports = router;
