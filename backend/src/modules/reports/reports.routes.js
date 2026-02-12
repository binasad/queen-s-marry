const express = require('express');
const router = express.Router();
const reportsController = require('./reports.controller');
const { auth } = require('../../middlewares/auth.middleware');

router.get('/sales', auth, reportsController.getSalesOverview);
router.get('/data', auth, reportsController.getReports);
router.get('/transactions', auth, reportsController.getTransactions);

module.exports = router;
