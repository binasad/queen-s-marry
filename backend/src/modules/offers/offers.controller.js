const { query } = require('../../config/db');

class OffersController {
  // Get all offers (public - only active ones)
  async getAllOffers(req, res) {
    try {
      const { isActive, page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = 'SELECT * FROM offers WHERE 1=1';
      const queryParams = [];
      let paramCounter = 1;

      // For public access, only show active offers that are within date range
      if (isActive === undefined || isActive === 'true') {
        queryText += ` AND is_active = $${paramCounter} AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE`;
        queryParams.push(true);
        paramCounter++;
      } else if (isActive === 'false') {
        queryText += ` AND is_active = $${paramCounter}`;
        queryParams.push(false);
        paramCounter++;
      }

      queryText += ` ORDER BY created_at DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM offers WHERE 1=1';
      const countParams = [];
      if (isActive === undefined || isActive === 'true') {
        countQuery += ' AND is_active = $1 AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE';
        countParams.push(true);
      } else if (isActive === 'false') {
        countQuery += ' AND is_active = $1';
        countParams.push(false);
      }

      const countResult = await query(countQuery, countParams);
      const totalOffers = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          offers: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalOffers,
            pages: Math.ceil(totalOffers / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get offers error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch offers.',
      });
    }
  }

  // Get all offers (admin - includes inactive and expired)
  async getAllOffersAdmin(req, res) {
    try {
      const { isActive, page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = 'SELECT * FROM offers WHERE 1=1';
      const queryParams = [];
      let paramCounter = 1;

      if (isActive !== undefined) {
        queryText += ` AND is_active = $${paramCounter}`;
        queryParams.push(isActive === 'true');
        paramCounter++;
      }

      queryText += ` ORDER BY created_at DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM offers WHERE 1=1';
      const countParams = [];
      if (isActive !== undefined) {
        countQuery += ` AND is_active = $1`;
        countParams.push(isActive === 'true');
      }

      const countResult = await query(countQuery, countParams);
      const totalOffers = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          offers: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalOffers,
            pages: Math.ceil(totalOffers / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get offers admin error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch offers.',
      });
    }
  }

  // Get offer by ID
  async getOfferById(req, res) {
    try {
      const { id } = req.params;

      const result = await query('SELECT * FROM offers WHERE id = $1', [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found.',
        });
      }

      res.json({
        success: true,
        data: { offer: result.rows[0] },
      });
    } catch (error) {
      console.error('Get offer error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch offer.',
      });
    }
  }

  // Create offer (Admin only)
  async createOffer(req, res) {
    try {
      const { title, description, discountPercentage, discountAmount, imageUrl, startDate, endDate, isActive, serviceId, courseId } = req.body;

      // Validate that at least one discount type is provided
      if (!discountPercentage && !discountAmount) {
        return res.status(400).json({
          success: false,
          message: 'Either discount percentage or discount amount is required.',
        });
      }

      const result = await query(
        `INSERT INTO offers (title, description, discount_percentage, discount_amount, image_url, start_date, end_date, is_active, service_id, course_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         RETURNING *`,
        [
          title,
          description || null,
          discountPercentage || null,
          discountAmount || null,
          imageUrl || null,
          startDate,
          endDate,
          isActive !== undefined ? isActive : true,
          serviceId || null,
          courseId || null,
        ]
      );

      const newOffer = result.rows[0];

      // Emit WebSocket event for real-time updates
      if (global.io) {
        global.io.to('admin').emit('offer-created', { offer: newOffer });
        global.io.emit('offers-updated', { action: 'created', offer: newOffer });
      }

      res.status(201).json({
        success: true,
        data: { offer: newOffer },
        message: 'Offer created successfully.',
      });
    } catch (error) {
      console.error('Create offer error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create offer.',
      });
    }
  }

  // Update offer (Admin only)
  async updateOffer(req, res) {
    try {
      const { id } = req.params;
      const { title, description, discountPercentage, discountAmount, imageUrl, startDate, endDate, isActive, serviceId, courseId } = req.body;

      // Build dynamic update query
      const updates = [];
      const values = [];
      let paramCounter = 1;

      if (title !== undefined) {
        updates.push(`title = $${paramCounter++}`);
        values.push(title);
      }
      if (description !== undefined) {
        updates.push(`description = $${paramCounter++}`);
        values.push(description);
      }
      if (discountPercentage !== undefined) {
        updates.push(`discount_percentage = $${paramCounter++}`);
        values.push(discountPercentage);
      }
      if (discountAmount !== undefined) {
        updates.push(`discount_amount = $${paramCounter++}`);
        values.push(discountAmount);
      }
      if (imageUrl !== undefined) {
        updates.push(`image_url = $${paramCounter++}`);
        values.push(imageUrl);
      }
      if (startDate !== undefined) {
        updates.push(`start_date = $${paramCounter++}`);
        values.push(startDate);
      }
      if (endDate !== undefined) {
        updates.push(`end_date = $${paramCounter++}`);
        values.push(endDate);
      }
      if (isActive !== undefined) {
        updates.push(`is_active = $${paramCounter++}`);
        values.push(isActive);
      }
      if (serviceId !== undefined) {
        updates.push(`service_id = $${paramCounter++}`);
        values.push(serviceId || null);
      }
      if (courseId !== undefined) {
        updates.push(`course_id = $${paramCounter++}`);
        values.push(courseId || null);
      }

      if (updates.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No fields to update.',
        });
      }

      updates.push(`updated_at = CURRENT_TIMESTAMP`);
      values.push(id);

      const result = await query(
        `UPDATE offers SET ${updates.join(', ')} WHERE id = $${paramCounter} RETURNING *`,
        values
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found.',
        });
      }

      const updatedOffer = result.rows[0];

      // Emit WebSocket event for real-time updates
      if (global.io) {
        global.io.to('admin').emit('offer-updated', { offer: updatedOffer });
        global.io.emit('offers-updated', { action: 'updated', offer: updatedOffer });
      }

      res.json({
        success: true,
        data: { offer: updatedOffer },
        message: 'Offer updated successfully.',
      });
    } catch (error) {
      console.error('Update offer error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update offer.',
      });
    }
  }

  // Delete offer (Admin only)
  async deleteOffer(req, res) {
    try {
      const { id } = req.params;

      const result = await query('DELETE FROM offers WHERE id = $1 RETURNING *', [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found.',
        });
      }

      const deletedOffer = result.rows[0];

      // Emit WebSocket event for real-time updates
      if (global.io) {
        global.io.to('admin').emit('offer-deleted', { offerId: id });
        global.io.emit('offers-updated', { action: 'deleted', offerId: id });
      }

      res.json({
        success: true,
        message: 'Offer deleted successfully.',
      });
    } catch (error) {
      console.error('Delete offer error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete offer.',
      });
    }
  }
}

module.exports = new OffersController();
