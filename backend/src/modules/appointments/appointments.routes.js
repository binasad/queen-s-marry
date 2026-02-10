
const express = require('express');
const router = express.Router();
const appointmentsController = require('./appointments.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission, blockGuests } = require('../../middlewares/role.middleware');
const { validationRules } = require('./appointments.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Recent appointments for dashboard
router.get(
  '/appointments/recent',
  auth,
  checkPermission('appointments.manage_all'),
  appointmentsController.getRecentAppointments
);

// User routes - blockGuests ensures only registered users can book
router.post(
  '/appointments',
  auth,
  blockGuests,  // Block guest users from creating appointments
  validationRules.createAppointment,
  handleValidationErrors,
  appointmentsController.createAppointment
);

router.get(
  '/appointments/my',
  auth,
  blockGuests,  // Guests don't have appointments to view
  appointmentsController.getUserAppointments
);

router.delete(
  '/appointments/:id/cancel',
  auth,
  blockGuests,
  validationRules.cancelAppointment,
  handleValidationErrors,
  appointmentsController.cancelAppointment
);

// Admin routes
router.get(
  '/appointments',
  auth,
  checkPermission('appointments.manage_all'),
  appointmentsController.getAllAppointments
);

router.put(
  '/appointments/:id/status',
  auth,
  checkPermission('appointments.manage_all'),
  validationRules.updateAppointmentStatus,
  handleValidationErrors,
  appointmentsController.updateAppointmentStatus
);

router.put(
  '/appointments/:id/pay',
  auth,
  checkPermission('appointments.manage_all'),
  validationRules.markAsPaid,
  handleValidationErrors,
  appointmentsController.markAsPaid
);

router.delete(
  '/appointments/:id',
  auth,
  checkPermission('appointments.manage_all'),
  appointmentsController.deleteAppointment
);

router.get(
  '/dashboard/stats',
  auth,
  checkPermission('appointments.manage_all'),
  appointmentsController.getDashboardStats
);

module.exports = router;
