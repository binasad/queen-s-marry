const express = require('express');
const router = express.Router();
const paymentsController = require('./payments.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { createIntentValidation } = require('./payments.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Recent payments for dashboard
router.get('/recent', auth, paymentsController.getRecentPayments);

// Create PaymentIntent with booking metadata (webhook creates appointment on success)
router.post('/create-intent', auth, createIntentValidation, handleValidationErrors, paymentsController.createPaymentIntent);

module.exports = router;