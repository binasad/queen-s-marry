const express = require('express');
const router = express.Router();
const reviewsController = require('./reviews.controller');
const { auth } = require('../../middlewares/auth.middleware');
const { blockGuests } = require('../../middlewares/role.middleware');

// Public routes - view reviews on services/courses
router.get('/reviews/by-service/:serviceId', reviewsController.getReviewsByService);
router.get('/reviews/by-course/:courseId', reviewsController.getReviewsByCourse);

// Customer routes - block guests
router.get('/reviews/my', auth, blockGuests, reviewsController.getMyReviews);
router.get('/reviews/my-course-reviews', auth, blockGuests, reviewsController.getMyCourseReviews);
router.get('/reviews/by-appointment/:appointmentId', auth, blockGuests, reviewsController.getReviewByAppointment);

router.post('/reviews', auth, blockGuests, reviewsController.createReview);
router.post('/reviews/course', auth, blockGuests, reviewsController.createCourseReview);

module.exports = router;
