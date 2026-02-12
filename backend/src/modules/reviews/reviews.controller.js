const { query } = require('../../config/db');

// Map rating 1-5 to sentiment labels (Excellent, Good, Bad, etc.)
const RATING_SENTIMENTS = {
  5: 'Excellent',
  4: 'Very Good',
  3: 'Good',
  2: 'Fair',
  1: 'Poor',
};

function addSentiment(rows) {
  return rows.map((r) => ({
    ...r,
    sentiment: RATING_SENTIMENTS[r.rating] || 'Good',
  }));
}

class ReviewsController {
  // Get current user's reviews
  async getMyReviews(req, res) {
    try {
      const result = await query(
        `SELECT r.id, r.rating, r.comment, r.created_at,
                r.appointment_id, r.service_id, r.expert_id,
                s.name as service_name, e.name as expert_name
         FROM reviews r
         LEFT JOIN services s ON r.service_id = s.id
         LEFT JOIN experts e ON r.expert_id = e.id
         WHERE r.user_id = $1
         ORDER BY r.created_at DESC`,
        [req.user.id]
      );

      res.json({
        success: true,
        data: { reviews: addSentiment(result.rows) },
      });
    } catch (error) {
      console.error('Get my reviews error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reviews.',
      });
    }
  }

  // Check if appointment already has a review from this user
  async getReviewByAppointment(req, res) {
    try {
      const { appointmentId } = req.params;
      const result = await query(
        'SELECT id, rating, comment, created_at FROM reviews WHERE user_id = $1 AND appointment_id = $2',
        [req.user.id, appointmentId]
      );

      if (result.rows.length === 0) {
        return res.json({ success: true, data: { review: null } });
      }

      res.json({
        success: true,
        data: { review: addSentiment([result.rows[0]])[0] },
      });
    } catch (error) {
      console.error('Get review by appointment error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch review.',
      });
    }
  }

  // Create review (customer only, for completed appointments)
  async createReview(req, res) {
    try {
      const { appointmentId, rating, comment } = req.body;

      if (!appointmentId || !rating || rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'appointmentId and rating (1-5) are required.',
        });
      }

      // Verify appointment belongs to user and is completed
      const aptResult = await query(
        `SELECT id, user_id, service_id, expert_id, status
         FROM appointments WHERE id = $1`,
        [appointmentId]
      );

      if (aptResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found.',
        });
      }

      const apt = aptResult.rows[0];
      if (apt.user_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'You can only review your own appointments.',
        });
      }

      if (apt.status !== 'completed') {
        return res.status(400).json({
          success: false,
          message: 'You can only review completed appointments.',
        });
      }

      // Check if already reviewed
      const existing = await query(
        'SELECT id FROM reviews WHERE user_id = $1 AND appointment_id = $2',
        [req.user.id, appointmentId]
      );

      if (existing.rows.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this appointment.',
        });
      }

      // Insert review
      const insertResult = await query(
        `INSERT INTO reviews (user_id, service_id, expert_id, appointment_id, rating, comment)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [req.user.id, apt.service_id, apt.expert_id, appointmentId, Math.round(rating), comment || null]
      );

      const newReview = insertResult.rows[0];

      // Update expert rating if expert exists
      if (apt.expert_id) {
        const aggResult = await query(
          `SELECT AVG(rating)::decimal(3,2) as avg_rating, COUNT(*) as total
           FROM reviews WHERE expert_id = $1`,
          [apt.expert_id]
        );
        const { avg_rating, total } = aggResult.rows[0] || {};
        if (avg_rating != null) {
          await query(
            'UPDATE experts SET rating = $1, total_reviews = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3',
            [parseFloat(avg_rating), parseInt(total, 10), apt.expert_id]
          );
        }
      }

      res.status(201).json({
        success: true,
        message: 'Review submitted successfully.',
        data: { review: addSentiment([newReview])[0] },
      });
    } catch (error) {
      console.error('Create review error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to submit review.',
      });
    }
  }

  // Get reviews by service (public - for service details page)
  async getReviewsByService(req, res) {
    try {
      const { serviceId } = req.params;
      const result = await query(
        `SELECT r.id, r.rating, r.comment, r.created_at, u.name as user_name, e.name as expert_name
         FROM reviews r
         LEFT JOIN users u ON r.user_id = u.id
         LEFT JOIN experts e ON r.expert_id = e.id
         WHERE r.service_id = $1
         ORDER BY r.created_at DESC
         LIMIT 50`,
        [serviceId]
      );

      const withSentiment = addSentiment(result.rows);
      const avgRating = result.rows.length > 0
        ? (result.rows.reduce((s, r) => s + parseInt(r.rating, 10), 0) / result.rows.length).toFixed(1)
        : 0;

      res.json({
        success: true,
        data: {
          reviews: withSentiment,
          averageRating: parseFloat(avgRating),
          totalCount: result.rows.length,
        },
      });
    } catch (error) {
      console.error('Get reviews by service error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reviews.',
      });
    }
  }

  // Get reviews by course (public - for course details page)
  async getReviewsByCourse(req, res) {
    try {
      const { courseId } = req.params;
      const result = await query(
        `SELECT r.id, r.rating, r.comment, r.created_at, u.name as user_name
         FROM course_reviews r
         LEFT JOIN users u ON r.user_id = u.id
         WHERE r.course_id = $1
         ORDER BY r.created_at DESC
         LIMIT 50`,
        [courseId]
      );

      const withSentiment = addSentiment(result.rows);
      const avgRating = result.rows.length > 0
        ? (result.rows.reduce((s, r) => s + parseInt(r.rating, 10), 0) / result.rows.length).toFixed(1)
        : 0;

      res.json({
        success: true,
        data: {
          reviews: withSentiment,
          averageRating: parseFloat(avgRating),
          totalCount: result.rows.length,
        },
      });
    } catch (error) {
      console.error('Get reviews by course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reviews.',
      });
    }
  }

  // Create course review (user must have approved course application)
  async createCourseReview(req, res) {
    try {
      const { courseId, rating, comment } = req.body;

      if (!courseId || !rating || rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'courseId and rating (1-5) are required.',
        });
      }

      const appResult = await query(
        'SELECT id FROM course_applications WHERE user_id = $1 AND course_id = $2 AND status = $3',
        [req.user.id, courseId, 'approved']
      );

      if (appResult.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'You can only review courses you have been approved for.',
        });
      }

      const existing = await query(
        'SELECT id FROM course_reviews WHERE user_id = $1 AND course_id = $2',
        [req.user.id, courseId]
      );

      if (existing.rows.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this course.',
        });
      }

      const insertResult = await query(
        `INSERT INTO course_reviews (course_id, user_id, rating, comment)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [courseId, req.user.id, Math.round(rating), comment || null]
      );

      const newReview = insertResult.rows[0];

      res.status(201).json({
        success: true,
        message: 'Review submitted successfully.',
        data: { review: addSentiment([newReview])[0] },
      });
    } catch (error) {
      console.error('Create course review error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to submit review.',
      });
    }
  }

  // Get current user's course reviews
  async getMyCourseReviews(req, res) {
    try {
      const result = await query(
        `SELECT r.id, r.rating, r.comment, r.created_at, r.course_id, c.title as course_title
         FROM course_reviews r
         LEFT JOIN courses c ON r.course_id = c.id
         WHERE r.user_id = $1
         ORDER BY r.created_at DESC`,
        [req.user.id]
      );

      res.json({
        success: true,
        data: { reviews: addSentiment(result.rows) },
      });
    } catch (error) {
      console.error('Get my course reviews error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reviews.',
      });
    }
  }
}

module.exports = new ReviewsController();
