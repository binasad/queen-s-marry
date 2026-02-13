const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { hasRole } = require('../../middlewares/role.middleware');

// Save FCM token
router.post('/notifications/save-token', auth, notificationsController.saveToken);

// Clear FCM token (guest users, logout)
router.post('/notifications/clear-token', auth, notificationsController.clearToken);

// Get FCM token status (for testing)
router.get('/notifications/token', auth, notificationsController.getToken);

// Get current user's notifications (for in-app list)
router.get('/notifications/my', auth, notificationsController.getMyNotifications);

// Test push – admin only (send test notification to a user)
router.post('/notifications/test/:userId', auth, hasRole(['Admin', 'Owner']), notificationsController.testPush);

module.exports = router;
