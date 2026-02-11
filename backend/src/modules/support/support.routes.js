const express = require('express');
const router = express.Router();
const supportController = require('./support.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules } = require('./support.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Public route - anyone can create a ticket
router.post('/support/tickets', auth, validationRules.createTicket, handleValidationErrors, supportController.createTicket);

// Admin routes
router.get(
  '/support/tickets',
  auth,
  checkPermission('support.view'),
  supportController.getAllTickets
);

router.get(
  '/support/tickets/:id',
  auth,
  checkPermission('support.view'),
  validationRules.getTicketById,
  handleValidationErrors,
  supportController.getTicketById
);

router.put(
  '/support/tickets/:id',
  auth,
  checkPermission('support.manage'),
  validationRules.updateTicket,
  handleValidationErrors,
  supportController.updateTicket
);

router.delete(
  '/support/tickets/:id',
  auth,
  checkPermission('support.manage'),
  validationRules.deleteTicket,
  handleValidationErrors,
  supportController.deleteTicket
);

module.exports = router;
