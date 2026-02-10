
const express = require('express');
const router = express.Router();
const paymentsController = require('./payments.controller');
const { auth } = require('../../middlewares/auth.middleware');

// Recent payments for dashboard
router.get('/recent', auth, paymentsController.getRecentPayments);

// This matches the Flutter call: /api/v1/payments/create-intent
router.post('/create-intent', auth, paymentsController.createPaymentIntent);

module.exports = router;