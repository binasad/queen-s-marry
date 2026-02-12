const { query } = require('../../config/db');

class BlogsController {
  // Get all active blogs (public - for mobile app)
  async getAll(req, res) {
    try {
      const { page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      const result = await query(
        `SELECT * FROM blogs 
         WHERE is_active = true 
         ORDER BY display_order ASC, created_at DESC 
         LIMIT $1 OFFSET $2`,
        [limit, offset]
      );

      const countResult = await query('SELECT COUNT(*) FROM blogs WHERE is_active = true');
      const total = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          blogs: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total,
            pages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get blogs error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch blogs.' });
    }
  }

  // Get all blogs (admin - includes inactive)
  async getAllAdmin(req, res) {
    try {
      const { page = 1, limit = 50, isActive } = req.query;
      const offset = (page - 1) * limit;

      let queryText = 'SELECT * FROM blogs WHERE 1=1';
      const queryParams = [];
      let paramCounter = 1;

      if (isActive !== undefined) {
        queryText += ` AND is_active = $${paramCounter}`;
        queryParams.push(isActive === 'true');
        paramCounter++;
      }

      queryText += ` ORDER BY display_order ASC, created_at DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      let countQuery = 'SELECT COUNT(*) FROM blogs WHERE 1=1';
      const countParams = [];
      if (isActive !== undefined) {
        countQuery += ' AND is_active = $1';
        countParams.push(isActive === 'true');
      }
      const countResult = await query(countQuery, countParams);
      const total = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          blogs: result.rows,
          pagination: { page: parseInt(page, 10), limit: parseInt(limit, 10), total, pages: Math.ceil(total / limit) },
        },
      });
    } catch (error) {
      console.error('Get blogs admin error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch blogs.' });
    }
  }

  // Get blog by ID
  async getById(req, res) {
    try {
      const { id } = req.params;
      const result = await query('SELECT * FROM blogs WHERE id = $1', [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Blog not found.' });
      }
      res.json({ success: true, data: { blog: result.rows[0] } });
    } catch (error) {
      console.error('Get blog error:', error);
      res.status(500).json({ success: false, message: 'Failed to fetch blog.' });
    }
  }

  // Create blog (admin)
  async create(req, res) {
    try {
      const { title, content, imageUrl, isActive = true, displayOrder = 0 } = req.body;
      const result = await query(
        `INSERT INTO blogs (title, content, image_url, is_active, display_order)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [title, content || '', imageUrl || null, isActive, displayOrder || 0]
      );
      res.status(201).json({ success: true, message: 'Blog created.', data: { blog: result.rows[0] } });
    } catch (error) {
      console.error('Create blog error:', error);
      res.status(500).json({ success: false, message: 'Failed to create blog.' });
    }
  }

  // Update blog (admin)
  async update(req, res) {
    try {
      const { id } = req.params;
      const { title, content, imageUrl, isActive, displayOrder } = req.body;

      const updateFields = [];
      const updateValues = [];
      let paramCounter = 1;

      if (title !== undefined) { updateFields.push(`title = $${paramCounter}`); updateValues.push(title); paramCounter++; }
      if (content !== undefined) { updateFields.push(`content = $${paramCounter}`); updateValues.push(content); paramCounter++; }
      if (imageUrl !== undefined) { updateFields.push(`image_url = $${paramCounter}`); updateValues.push(imageUrl); paramCounter++; }
      if (isActive !== undefined) { updateFields.push(`is_active = $${paramCounter}`); updateValues.push(isActive); paramCounter++; }
      if (displayOrder !== undefined) { updateFields.push(`display_order = $${paramCounter}`); updateValues.push(displayOrder); paramCounter++; }

      if (updateFields.length === 0) {
        return res.status(400).json({ success: false, message: 'No fields to update.' });
      }

      updateFields.push('updated_at = CURRENT_TIMESTAMP');
      updateValues.push(id);

      const result = await query(
        `UPDATE blogs SET ${updateFields.join(', ')} WHERE id = $${paramCounter} RETURNING *`,
        updateValues
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Blog not found.' });
      }
      res.json({ success: true, message: 'Blog updated.', data: { blog: result.rows[0] } });
    } catch (error) {
      console.error('Update blog error:', error);
      res.status(500).json({ success: false, message: 'Failed to update blog.' });
    }
  }

  // Delete blog (admin)
  async delete(req, res) {
    try {
      const { id } = req.params;
      const result = await query('DELETE FROM blogs WHERE id = $1 RETURNING id', [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Blog not found.' });
      }
      res.json({ success: true, message: 'Blog deleted.' });
    } catch (error) {
      console.error('Delete blog error:', error);
      res.status(500).json({ success: false, message: 'Failed to delete blog.' });
    }
  }
}

module.exports = new BlogsController();
