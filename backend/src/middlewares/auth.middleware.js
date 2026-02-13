const { verifyAccessToken } = require('../utils/jwt');
const { query } = require('../config/db');

/**
 * Authentication middleware
 * Verifies JWT token and attaches user to request
 */
const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No authentication token provided.',
      });
    }

    // Handle hardcoded admin token for development
    if (token.startsWith('admin-hardcoded-token-')) {
      req.user = {
        id: 'admin-hardcoded-id',
        email: 'admin@salon.com',
        roleId: 'admin-role-id',
        roleName: 'Owner',
        permissions: [
          'users.view',
          'users.manage',
          'services.manage',
          'appointments.view',
          'appointments.manage_all',
          'dashboard.view',
          'roles.view',
          'roles.manage',
          'courses.manage',
          'experts.manage',
          'support.view',
          'support.manage',
        ],
        email_verified: true,
      };
      return next();
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Guest tokens: session-only, no database lookup (privacy-first)
    if (decoded.isGuest === true && decoded.sessionId) {
      req.user = {
        id: null,
        sessionId: decoded.sessionId,
        isGuest: true,
        roleName: 'Guest',
        email: null,
        roleId: null,
        permissions: [],
        email_verified: true,
      };
      return next();
    }

    // Regular users: get from database
    const result = await query(
      `SELECT
         u.id,
         u.email,
         u.email_verified,
         u.role_id,
         r.name AS role_name,
         COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
       FROM users u
       LEFT JOIN roles r ON u.role_id = r.id
       LEFT JOIN role_permissions rp ON rp.role_id = r.id
       LEFT JOIN permissions p ON p.id = rp.permission_id
       WHERE u.id = $1
       GROUP BY u.id, r.id`,
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid authentication token.',
      });
    }

    const user = result.rows[0];

    // Check email verification
    if (!user.email_verified) {
      return res.status(403).json({
        success: false,
        message: 'Please verify your email to continue.',
      });
    }

    // Attach user to request
    req.user = {
      id: user.id,
      email: user.email,
      roleId: user.role_id,
      roleName: user.role_name,
      permissions: user.permissions || [],
      email_verified: user.email_verified,
    };
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid authentication token.',
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Authentication token expired.',
      });
    }
    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Authentication failed.',
    });
  }
};

/**
 * Optional authentication middleware
 * Does not fail if token is missing
 */
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return next();
    }

    const decoded = verifyAccessToken(token);

    if (decoded.isGuest === true && decoded.sessionId) {
      req.user = {
        id: null,
        sessionId: decoded.sessionId,
        isGuest: true,
        roleName: 'Guest',
        email: null,
        roleId: null,
        permissions: [],
        email_verified: true,
      };
      return next();
    }

    const result = await query(
      `SELECT
         u.id,
         u.email,
         u.email_verified,
         u.role_id,
         r.name AS role_name,
         COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
       FROM users u
       LEFT JOIN roles r ON u.role_id = r.id
       LEFT JOIN role_permissions rp ON rp.role_id = r.id
       LEFT JOIN permissions p ON p.id = rp.permission_id
       WHERE u.id = $1
       GROUP BY u.id, r.id`,
      [decoded.id]
    );

    if (result.rows.length > 0) {
      const user = result.rows[0];
      req.user = {
        id: user.id,
        email: user.email,
        roleId: user.role_id,
        roleName: user.role_name,
        permissions: user.permissions || [],
        email_verified: user.email_verified,
      };
    }

    next();
  } catch (error) {
    // Silent fail for optional auth
    next();
  }
};

module.exports = { auth, optionalAuth };
