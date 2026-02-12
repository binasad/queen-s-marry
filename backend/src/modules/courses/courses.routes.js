const express = require('express');
const router = express.Router();
const coursesController = require('./courses.controller');
const { auth, optionalAuth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules } = require('./courses.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Public routes
router.get('/courses', coursesController.getAllCourses);
router.post('/courses/:id/apply', optionalAuth, coursesController.applyForCourse);
router.get(
  '/courses/:id',
  validationRules.getCourseById,
  handleValidationErrors,
  coursesController.getCourseById
);

// Admin routes
router.post(
  '/courses',
  auth,
  checkPermission('courses.manage'),
  validationRules.createCourse,
  handleValidationErrors,
  coursesController.createCourse
);

router.put(
  '/courses/:id',
  auth,
  checkPermission('courses.manage'),
  validationRules.updateCourse,
  handleValidationErrors,
  coursesController.updateCourse
);

router.delete(
  '/courses/:id',
  auth,
  checkPermission('courses.manage'),
  validationRules.deleteCourse,
  handleValidationErrors,
  coursesController.deleteCourse
);

router.get(
  '/courses/admin/applications',
  auth,
  checkPermission('courses.manage'),
  coursesController.getAllApplications
);

module.exports = router;
