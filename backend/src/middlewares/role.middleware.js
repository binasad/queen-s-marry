/**
 * Role & permission authorization middleware
 */

/**
 * Check if user has specific permission slug
 * @param {string|string[]} permissions
 */
const checkPermission = (permissions) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    const required = Array.isArray(permissions) ? permissions : [permissions];
    const userPerms = req.user.permissions || [];
    const hasPerm = required.every((perm) => userPerms.includes(perm));

    if (!hasPerm) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Insufficient permissions.',
      });
    }

    next();
  };
};

/**
 * Check if user has specific role name(s)
 */
const hasRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    const allowedRoles = Array.isArray(roles) ? roles : [roles];
    if (allowedRoles.includes(req.user.roleName)) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: 'Access denied. Insufficient role.',
    });
  };
};

/**
 * Block guest users from accessing certain routes
 * Returns a user-friendly message prompting them to create an account
 */
const blockGuests = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required.',
    });
  }

  // Check if user is a guest (by role name or isGuest flag from token)
  if (req.user.roleName === 'Guest' || req.user.isGuest) {
    return res.status(403).json({
      success: false,
      code: 'GUEST_RESTRICTED',
      message: 'This feature requires a registered account. Please sign up to continue.',
    });
  }

  next();
};

/**
 * Require registered user (not guest) with specific permission
 */
const requireRegisteredWithPermission = (permissions) => {
  return [blockGuests, checkPermission(permissions)];
};

module.exports = {
  checkPermission,
  hasRole,
  blockGuests,
  requireRegisteredWithPermission,
};
