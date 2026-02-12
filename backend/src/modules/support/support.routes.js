const express = require('express');
const router = express.Router();
const supportController = require('./support.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission, blockGuests } = require('../../middlewares/role.middleware');
const { validationRules } = require('./support.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// User route - get my own tickets (must be before /:id)
router.get('/support/tickets/my', auth, blockGuests, supportController.getMyTickets);

// Create ticket - only registered users (no guests)
router.post('/support/tickets', auth, blockGuests, validationRules.createTicket, handleValidationErrors, supportController.createTicket);

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
