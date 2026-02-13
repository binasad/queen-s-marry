const { query } = require('../../config/db');
const pushService = require('../../services/pushNotificationService');

class NotificationsController {
  // Save FCM token for a user
  async saveToken(req, res) {
    try {
      if (req.user?.isGuest || !req.user?.id) {
        return res.json({ success: true, message: 'Guests do not receive push notifications.' });
      }
      const { fcmToken } = req.body;
      const userId = req.user.id;

      if (!fcmToken) {
        return res.status(400).json({
          success: false,
          message: 'FCM token is required.',
        });
      }

      // Check if users table has fcm_token column, if not we'll add it via migration
      // For now, update the user's record with the new token
      const result = await query(
        `UPDATE users 
         SET fcm_token = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2 
         RETURNING id, email`,
        [fcmToken, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      console.log(`✅ FCM token saved for user ${userId} (${result.rows[0].email})`);
      res.json({
        success: true,
        message: 'FCM token saved successfully.',
        data: { userId: result.rows[0].id },
      });
    } catch (error) {
      console.error('Save FCM token error:', error);
      
      // If column doesn't exist, provide helpful error
      if (error.code === '42703') { // undefined_column
        return res.status(500).json({
          success: false,
          message: 'FCM token column not found. Please run database migration to add fcm_token column to users table.',
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to save FCM token.',
      });
    }
  }

  // Clear FCM token (e.g. when user switches to guest or logs out)
  async clearToken(req, res) {
    try {
      if (req.user?.isGuest || !req.user?.id) {
        return res.json({ success: true, message: 'No token to clear.' });
      }
      const userId = req.user.id;

      await query(
        `UPDATE users 
         SET fcm_token = NULL, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $1`,
        [userId]
      );

      res.json({
        success: true,
        message: 'FCM token cleared.',
      });
    } catch (error) {
      console.error('Clear FCM token error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to clear FCM token.',
      });
    }
  }

  // Get user's FCM token (for admin/testing)
  async getToken(req, res) {
    try {
      if (req.user?.isGuest || !req.user?.id) {
        return res.json({ success: true, data: { hasToken: false } });
      }
      const userId = req.user.id;

      const result = await query(
        'SELECT fcm_token FROM users WHERE id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      res.json({
        success: true,
        data: { 
          hasToken: !!result.rows[0].fcm_token,
          // Don't return actual token for security
        },
      });
    } catch (error) {
      console.error('Get FCM token error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get FCM token.',
      });
    }
  }

  // Get current user's notifications (for in-app list)
  async getMyNotifications(req, res) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.json({ success: true, data: [] });
      }
      const result = await query(
        `SELECT id, title, message, type, is_read, created_at 
         FROM notifications 
         WHERE user_id = $1 
         ORDER BY created_at DESC 
         LIMIT 100`,
        [userId]
      );
      res.json({
        success: true,
        data: result.rows,
      });
    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch notifications.',
      });
    }
  }

  // Test push (admin only) – POST /notifications/test/:userId
  async testPush(req, res) {
    try {
      const { userId } = req.params;
      const { title, body } = req.body || {};

      const userResult = await query(
        'SELECT u.id, u.email, u.fcm_token, r.name AS role_name FROM users u LEFT JOIN roles r ON u.role_id = r.id WHERE u.id = $1',
        [userId]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found.' });
      }
      const user = userResult.rows[0];
      if (!user.fcm_token) {
        return res.status(400).json({
          success: false,
          message: `User ${user.email || userId} has no FCM token. Have them open the app, log in, and allow notifications.`,
        });
      }

      await pushService.sendToToken(user.fcm_token, {
        title: title || 'Test Notification',
        body: body || 'This is a test push from Merry Queen Salon.',
        data: { type: 'test' },
      });
      // Store in DB so it appears in notifications screen
      await query(
        'INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)',
        [userId, title || 'Test Notification', body || 'This is a test push from Merry Queen Salon.', 'test']
      );

      res.json({
        success: true,
        message: 'Test notification sent.',
        data: { userId, email: user.email },
      });
    } catch (error) {
      console.error('Test push error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to send test notification.',
      });
    }
  }
}

module.exports = new NotificationsController();
