const express = require('express');
const router = express.Router();
const rolesController = require('./roles.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules, handleValidationErrors } = require('./roles.validation');

router.get(
  '/permissions',
  auth,
  checkPermission('roles.view'),
  rolesController.listPermissions
);

router.get(
  '/roles',
  auth,
  checkPermission('roles.view'),
  rolesController.listRoles
);

router.post(
  '/roles',
  auth,
  checkPermission('roles.manage'),
  validationRules.createRole,
  handleValidationErrors,
  rolesController.createRole
);

router.put(
  '/roles/:id/permissions',
  auth,
  checkPermission('roles.manage'),
  validationRules.updatePermissions,
  handleValidationErrors,
  rolesController.updateRolePermissions
);

module.exports = router;
