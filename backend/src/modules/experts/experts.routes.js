const express = require('express');
const router = express.Router();
const expertsController = require('./experts.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules } = require('./experts.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Public routes
router.get('/experts', expertsController.getAllExperts);
router.get(
  '/experts/:id',
  validationRules.getExpertById,
  handleValidationErrors,
  expertsController.getExpertById
);

// Admin routes
router.post(
  '/experts',
  auth,
  checkPermission('experts.manage'),
  validationRules.createExpert,
  handleValidationErrors,
  expertsController.createExpert
);

router.put(
  '/experts/:id',
  auth,
  checkPermission('experts.manage'),
  validationRules.updateExpert,
  handleValidationErrors,
  expertsController.updateExpert
);

router.delete(
  '/experts/:id',
  auth,
  checkPermission('experts.manage'),
  validationRules.deleteExpert,
  handleValidationErrors,
  expertsController.deleteExpert
);

module.exports = router;
