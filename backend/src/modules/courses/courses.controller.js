const { query } = require('../../config/db');

class CoursesController {
  // Get all courses
  async getAllCourses(req, res) {
    try {
      const { search, isActive, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = 'SELECT * FROM courses WHERE 1=1';
      const queryParams = [];
      let paramCounter = 1;

      if (search) {
        queryText += ` AND (title ILIKE $${paramCounter} OR description ILIKE $${paramCounter})`;
        queryParams.push(`%${search}%`);
        paramCounter++;
      }

      if (isActive !== undefined) {
        queryText += ` AND is_active = $${paramCounter}`;
        queryParams.push(isActive === 'true');
        paramCounter++;
      }

      queryText += ` ORDER BY created_at DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM courses WHERE 1=1';
      const countParams = [];
      if (search) {
        countQuery += ' AND (title ILIKE $1 OR description ILIKE $1)';
        countParams.push(`%${search}%`);
      }
      if (isActive !== undefined) {
        countQuery += ` AND is_active = $${countParams.length + 1}`;
        countParams.push(isActive === 'true');
      }

      const countResult = await query(countQuery, countParams);
      const totalCourses = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          courses: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalCourses,
            pages: Math.ceil(totalCourses / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get courses error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch courses.',
      });
    }
  }

  // Get course by ID
  async getCourseById(req, res) {
    try {
      const { id } = req.params;

      const result = await query('SELECT * FROM courses WHERE id = $1', [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Course not found.',
        });
      }

      res.json({
        success: true,
        data: { course: result.rows[0] },
      });
    } catch (error) {
      console.error('Get course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch course.',
      });
    }
  }

  // Create course (Admin only)
  async createCourse(req, res) {
    try {
      const { title, description, duration, price, imageUrl } = req.body;

      const result = await query(
        `INSERT INTO courses (title, description, duration, price, image_url)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [title, description || null, duration || null, price || null, imageUrl || null]
      );

      const newCourse = result.rows[0];
      if (global.io) {
        console.log('📢 Emitting course-created and courses-updated events');
        global.io.to('admin').emit('course-created', { course: newCourse });
        global.io.emit('courses-updated', { action: 'created', course: newCourse });
      }

      res.status(201).json({
        success: true,
        message: 'Course created successfully.',
        data: { course: result.rows[0] },
      });
    } catch (error) {
      console.error('Create course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create course.',
      });
    }
  }

  // Update course (Admin only)
  async updateCourse(req, res) {
    try {
      const { id } = req.params;
      const { title, description, duration, price, imageUrl, isActive } = req.body;

      const result = await query(
        `UPDATE courses
         SET title = COALESCE($1, title),
             description = COALESCE($2, description),
             duration = COALESCE($3, duration),
             price = COALESCE($4, price),
             image_url = COALESCE($5, image_url),
             is_active = COALESCE($6, is_active),
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $7
         RETURNING *`,
        [title, description, duration, price, imageUrl, isActive, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Course not found.',
        });
      }

      const updatedCourse = result.rows[0];
      if (global.io) {
        console.log('📢 Emitting course-updated and courses-updated events');
        global.io.to('admin').emit('course-updated', { course: updatedCourse });
        global.io.emit('courses-updated', { action: 'updated', course: updatedCourse });
      }

      res.json({
        success: true,
        message: 'Course updated successfully.',
        data: { course: result.rows[0] },
      });
    } catch (error) {
      console.error('Update course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update course.',
      });
    }
  }

  // Apply for course (user or guest)
  async applyForCourse(req, res) {
    try {
      const { id } = req.params;
      const { customerName, customerEmail, customerPhone, offerId } = req.body;

      const courseResult = await query('SELECT id, title FROM courses WHERE id = $1 AND is_active = TRUE', [id]);
      if (courseResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Course not found.' });
      }

      const userId = req.user?.id || null;
      const name = customerName?.trim() || 'Applicant';
      const email = customerEmail?.trim() || null;
      const phone = customerPhone?.trim() || null;

      if (!email && !phone) {
        return res.status(400).json({ success: false, message: 'Email or phone is required.' });
      }
      if (phone && String(phone).length < 5) {
        return res.status(400).json({ success: false, message: 'A valid phone number is required.' });
      }

      let appliedOfferId = null;
      if (offerId) {
        const offerResult = await query(
          `SELECT id FROM offers WHERE id = $1 AND is_active = TRUE 
           AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE 
           AND (course_id IS NULL OR course_id = $2)`,
          [offerId, id]
        );
        if (offerResult.rows.length > 0) appliedOfferId = offerResult.rows[0].id;
      }

      const result = await query(
        `INSERT INTO course_applications (user_id, course_id, offer_id, customer_name, customer_email, customer_phone)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [userId, id, appliedOfferId, name, email, phone]
      );

      const application = result.rows[0];
      if (global.io) {
        global.io.to('admin').emit('course-application-created', { application });
      }

      res.status(201).json({
        success: true,
        message: 'Application submitted successfully.',
        data: { application },
      });
    } catch (error) {
      console.error('Apply for course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to submit application.',
      });
    }
  }

  // Get all course applications (Admin only)
  async getAllApplications(req, res) {
    try {
      const result = await query(
        `SELECT ca.*, c.title as course_title, o.title as offer_title
         FROM course_applications ca
         JOIN courses c ON ca.course_id = c.id
         LEFT JOIN offers o ON ca.offer_id = o.id
         ORDER BY ca.applied_at DESC`
      );

      res.json({
        success: true,
        data: { applications: result.rows },
      });
    } catch (error) {
      console.error('Get course applications error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch applications.',
      });
    }
  }

  // Delete course (Admin only - soft delete)
  async deleteCourse(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        'UPDATE courses SET is_active = FALSE WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Course not found.',
        });
      }

      // Emit WebSocket event for real-time updates
      if (global.io) {
        global.io.to('admin').emit('course-deleted', { courseId: id });
        global.io.emit('courses-updated', { action: 'deleted', courseId: id });
      }

      res.json({
        success: true,
        message: 'Course deleted successfully.',
      });
    } catch (error) {
      console.error('Delete course error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete course.',
      });
    }
  }
}

module.exports = new CoursesController();
