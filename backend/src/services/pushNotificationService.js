const admin = require('firebase-admin');
const path = require('path');
const { query } = require('../config/db');

let isInitialized = false;

function initFirebase() {
  if (isInitialized) return true;
  try {
    const credentialPath = path.join(process.cwd(), 'firebase-admin-sdk.json');
    const fs = require('fs');
    if (fs.existsSync(credentialPath)) {
      const serviceAccount = require(credentialPath);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      isInitialized = true;
      console.log('✅ Firebase Admin initialized for push notifications');
      return true;
    } else {
      console.warn('⚠️ firebase-admin-sdk.json not found - push notifications disabled');
      return false;
    }
  } catch (err) {
    console.error('❌ Firebase Admin init error:', err.message);
    return false;
  }
}

/**
 * Send push notification to a user by user ID
 * @param {string} userId - User ID (fetches fcm_token from DB)
 * @param {object} payload - { title, body, data? }
 */
async function sendToUser(userId, { title, body, data = {}, type = 'general' }) {
  if (!initFirebase()) return;
  try {
    const result = await query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
    const token = result.rows[0]?.fcm_token;
    if (token) {
      await sendToToken(token, { title, body, data });
    } else {
      console.warn(`Push: No FCM token for user ${userId}`);
    }
    // Always store in DB so user sees it in the notifications screen
    const notifType = data?.type || type;
    await query(
      `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`,
      [userId, title || 'Merry Queen Salon', body || 'You have a new notification', notifType]
    );
  } catch (err) {
    console.error('Send push to user error:', err.message);
  }
}

/**
 * Send push notification to an FCM token
 * Uses "notification" payload so it displays when app is closed/background
 */
async function sendToToken(token, { title, body, data = {} }) {
  if (!initFirebase()) return;
  try {
    const message = {
      token,
      notification: {
        title: title || 'Merry Queen Salon',
        body: body || 'You have a new notification',
      },
      data: {
        ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'default',
          priority: 'max',
          defaultSound: true,
          defaultVibrateTimings: true,
          visibility: 'public',
          notificationCount: 1,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    await admin.messaging().send(message);
    console.log('📤 Push sent:', title);
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered') {
      await query('UPDATE users SET fcm_token = NULL WHERE fcm_token = $1', [token]);
    }
    console.error('Push send error:', err.message);
  }
}

/**
 * Send to multiple users (e.g. admins)
 */
async function sendToUsers(userIds, { title, body, data = {} }) {
  for (const id of userIds) {
    await sendToUser(id, { title, body, data });
  }
}

/**
 * Get user IDs with FCM tokens for Admin/Owner roles - for admin notifications
 */
async function getAdminUserIds() {
  try {
    const result = await query(
      `SELECT u.id FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE r.name IN ('Admin', 'Owner') AND u.fcm_token IS NOT NULL`
    );
    return result.rows.map(r => r.id);
  } catch (err) {
    console.error('Get admin IDs error:', err.message);
    return [];
  }
}

/**
 * Send push to all admins (e.g. new course application)
 */
async function sendToAdmins({ title, body, data = {} }) {
  const adminIds = await getAdminUserIds();
  await sendToUsers(adminIds, { title, body, data });
}

/**
 * Get user IDs with FCM tokens for Customer/User roles (app users who book services)
 */
async function getCustomerUserIds() {
  try {
    const result = await query(
      `SELECT u.id FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE r.name IN ('Customer', 'User') AND u.fcm_token IS NOT NULL`
    );
    return result.rows.map(r => r.id);
  } catch (err) {
    console.error('Get customer IDs error:', err.message);
    return [];
  }
}

/**
 * Send push to all customers (e.g. new offer)
 */
async function sendToCustomers({ title, body, data = {} }) {
  const customerIds = await getCustomerUserIds();
  await sendToUsers(customerIds, { title, body, data });
}

module.exports = {
  initFirebase,
  sendToUser,
  sendToToken,
  sendToUsers,
  sendToAdmins,
  sendToCustomers,
};
