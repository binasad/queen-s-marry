const express = require('express');
const router = express.Router();
const multer = require('multer');
const servicesController = require('./services.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules } = require('./services.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed.'), false);
    }
  },
});

// Public routes
router.get('/categories', servicesController.getCategories);
router.get('/services', servicesController.getAllServices);

// Admin routes - Categories
router.post(
  '/categories',
  auth,
  checkPermission('services.manage'),
  validationRules.createCategory,
  handleValidationErrors,
  servicesController.createCategory
);
router.get(
  '/services/:id',
  validationRules.getServiceById,
  handleValidationErrors,
  servicesController.getServiceById
);
router.get('/experts', servicesController.getAllExperts);

// Admin routes
router.post(
  '/services',
  auth,
  checkPermission('services.manage'),
  validationRules.createService,
  handleValidationErrors,
  servicesController.createService
);

router.put(
  '/services/:id',
  auth,
  checkPermission('services.manage'),
  validationRules.updateService,
  handleValidationErrors,
  servicesController.updateService
);

router.delete(
  '/services/:id',
  auth,
  checkPermission('services.manage'),
  validationRules.deleteService,
  handleValidationErrors,
  servicesController.deleteService
);

// Image upload route - any authenticated user (profile, services, etc.)
router.post(
  '/upload-image',
  auth,
  upload.single('image'),
  servicesController.uploadImage
);

module.exports = router;
