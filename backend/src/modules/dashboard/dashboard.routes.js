const express = require('express');
const router = express.Router();
const appointmentsController = require('../appointments/appointments.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');

// GET /api/v1/dashboard/stats
router.get(
  '/stats',
  auth,
  checkPermission('dashboard.view'),
  appointmentsController.getDashboardStats
);

module.exports = router;
