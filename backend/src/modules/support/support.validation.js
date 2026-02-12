const { body, param } = require('express-validator');

// Allow guest placeholder emails (e.g. guest_uuid@salon.guest)
const isEmailOrGuestEmail = (value) => {
  if (!value || typeof value !== 'string') return false;
  const trimmed = value.trim();
  if (!trimmed) return false;
  if (/^guest_[a-f0-9-]+@salon\.guest$/i.test(trimmed)) return true;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(trimmed);
};

const validationRules = {
  createTicket: [
    body('customerName')
      .trim()
      .notEmpty()
      .withMessage('Customer name is required')
      .isLength({ max: 255 })
      .withMessage('Name must be less than 255 characters'),
    body('customerEmail')
      .trim()
      .notEmpty()
      .withMessage('Customer email is required')
      .custom(isEmailOrGuestEmail)
      .withMessage('Invalid email address'),
    body('customerPhone')
      .optional()
      .trim()
      .isLength({ max: 20 })
      .withMessage('Phone must be less than 20 characters'),
    body('subject')
      .trim()
      .notEmpty()
      .withMessage('Subject is required')
      .isLength({ max: 255 })
      .withMessage('Subject must be less than 255 characters'),
    body('message')
      .trim()
      .notEmpty()
      .withMessage('Message is required'),
  ],

  updateTicket: [
    param('id')
      .isUUID()
      .withMessage('Invalid ticket ID'),
    body('status')
      .optional()
      .isIn(['open', 'in_progress', 'resolved', 'closed'])
      .withMessage('Invalid status'),
    body('priority')
      .optional()
      .isIn(['low', 'medium', 'high', 'urgent'])
      .withMessage('Invalid priority'),
    body('assignedTo')
      .optional()
      .isUUID()
      .withMessage('Invalid assigned user ID'),
    body('response')
      .optional()
      .trim(),
  ],

  deleteTicket: [
    param('id')
      .isUUID()
      .withMessage('Invalid ticket ID'),
  ],

  getTicketById: [
    param('id')
      .isUUID()
      .withMessage('Invalid ticket ID'),
  ],
};

module.exports = { validationRules };
