const express = require('express');
const router = express.Router();
const favoritesController = require('./favorites.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { blockGuests } = require('../../middlewares/role.middleware');
const { validationRules } = require('./favorites.validation');
const { handleValidationErrors } = require('../auth/auth.validation');

// All routes require auth + registered user (no guests)
router.get('/favorites', auth, blockGuests, favoritesController.getFavorites);

router.post(
  '/favorites',
  auth,
  blockGuests,
  validationRules.addFavorite,
  handleValidationErrors,
  favoritesController.addFavorite
);

router.delete(
  '/favorites/:itemType/:itemId',
  auth,
  blockGuests,
  validationRules.removeFavorite,
  handleValidationErrors,
  favoritesController.removeFavorite
);

router.get(
  '/favorites/check/:itemType/:itemId',
  auth,
  blockGuests,
  validationRules.checkFavorite,
  handleValidationErrors,
  favoritesController.checkFavorite
);

module.exports = router;