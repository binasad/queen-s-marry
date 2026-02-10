const express = require('express');
const router = express.Router();
const offersController = require('./offers.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');
const { validationRules } = require('./offers.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// Public routes - only active offers within date range
router.get('/offers', offersController.getAllOffers);

// Admin routes - all offers (including inactive/expired)
router.get(
  '/offers/admin',
  auth,
  checkPermission('offers.manage'),
  offersController.getAllOffersAdmin
);

router.get(
  '/offers/:id',
  validationRules.getOfferById,
  handleValidationErrors,
  offersController.getOfferById
);

router.post(
  '/offers',
  auth,
  checkPermission('offers.manage'),
  validationRules.createOffer,
  handleValidationErrors,
  offersController.createOffer
);

router.put(
  '/offers/:id',
  auth,
  checkPermission('offers.manage'),
  validationRules.updateOffer,
  handleValidationErrors,
  offersController.updateOffer
);

router.delete(
  '/offers/:id',
  auth,
  checkPermission('offers.manage'),
  validationRules.deleteOffer,
  handleValidationErrors,
  offersController.deleteOffer
);

module.exports = router;
