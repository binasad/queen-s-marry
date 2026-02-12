const express = require('express');
const router = express.Router();
const blogsController = require('./blogs.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { checkPermission } = require('../../middlewares/role.middleware');

// Public - active blogs only (mobile app)
router.get('/blogs', blogsController.getAll);

// Admin routes (must be before /:id)
router.get('/blogs/admin', auth, checkPermission('offers.manage'), blogsController.getAllAdmin);

router.get('/blogs/:id', blogsController.getById);
router.post('/blogs', auth, checkPermission('offers.manage'), blogsController.create);
router.put('/blogs/:id', auth, checkPermission('offers.manage'), blogsController.update);
router.delete('/blogs/:id', auth, checkPermission('offers.manage'), blogsController.delete);

module.exports = router;
