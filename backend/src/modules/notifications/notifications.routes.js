const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const { auth } = require('../../middlewares/auth.middleware');

// Save FCM token
router.post('/notifications/save-token', auth, notificationsController.saveToken);

// Clear FCM token (guest users, logout)
router.post('/notifications/clear-token', auth, notificationsController.clearToken);

// Get FCM token status (for testing)
router.get('/notifications/token', auth, notificationsController.getToken);

module.exports = router;
