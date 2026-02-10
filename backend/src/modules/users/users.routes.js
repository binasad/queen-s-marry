const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission, blockGuests } = require('../../middlewares/role.middleware');
const { validationRules } = require('./users.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// User profile routes (authenticated users)
router.get('/profile', auth, usersController.getProfile);
router.put(
  '/profile',
  auth,
  blockGuests,  // Guests cannot update profile
  validationRules.updateProfile,
  handleValidationErrors,
  usersController.updateProfile
);

// Admin routes
router.get(
  '/users',
  auth,
  checkPermission('users.manage'),
  usersController.getAllUsers
);

router.get(
  '/users/:id',
  auth,
  checkPermission('users.manage'),
  validationRules.getUserById,
  handleValidationErrors,
  usersController.getUserById
);

router.delete(
  '/users/:id',
  auth,
  checkPermission('users.manage'),
  validationRules.deleteUser,
  handleValidationErrors,
  usersController.deleteUser
);

// Assign role to user by email
router.post(
  '/users/assign-role',
  auth,
  checkPermission('users.manage'),
  validationRules.assignRoleByEmail,
  handleValidationErrors,
  usersController.assignRoleByEmail
);

// Assign role to multiple users by email
router.post(
  '/users/assign-role-multiple',
  auth,
  checkPermission('users.manage'),
  validationRules.assignRoleToMultiple,
  handleValidationErrors,
  usersController.assignRoleToMultiple
);

module.exports = router;
