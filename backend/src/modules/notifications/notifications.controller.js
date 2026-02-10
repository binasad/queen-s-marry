const { query } = require('../../config/db');

class NotificationsController {
  // Save FCM token for a user
  async saveToken(req, res) {
    try {
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

  // Get user's FCM token (for admin/testing)
  async getToken(req, res) {
    try {
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
}

module.exports = new NotificationsController();
