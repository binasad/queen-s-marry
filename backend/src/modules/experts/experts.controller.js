const { query, transaction } = require('../../config/db');

class ExpertsController {
  // Get all experts
  async getAllExperts(req, res) {
    try {
      const { serviceId, search, isActive, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      // Use alias e for consistency (required for ORDER BY and optional filters)
      let queryText = 'SELECT e.* FROM experts e WHERE 1=1';
      const queryParams = [];
      let paramCounter = 1;

      if (serviceId) {
        queryText = `
          SELECT DISTINCT e.* FROM experts e
          JOIN expert_services es ON e.id = es.expert_id
          WHERE es.service_id = $${paramCounter}
        `;
        queryParams.push(serviceId);
        paramCounter++;
      }

      if (search) {
        queryText += ` AND (e.name ILIKE $${paramCounter} OR e.specialty ILIKE $${paramCounter} OR e.email ILIKE $${paramCounter})`;
        queryParams.push(`%${search}%`);
        paramCounter++;
      }

      if (isActive !== undefined) {
        queryText += ` AND e.is_active = $${paramCounter}`;
        queryParams.push(isActive === 'true');
        paramCounter++;
      }

      queryText += ` ORDER BY e.rating DESC NULLS LAST, e.name ASC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM experts e WHERE 1=1';
      const countParams = [];
      if (serviceId) {
        countQuery = `
          SELECT COUNT(DISTINCT e.id) FROM experts e
          JOIN expert_services es ON e.id = es.expert_id
          WHERE es.service_id = $1
        `;
        countParams.push(serviceId);
      }
      if (search && !serviceId) {
        countQuery += ' AND (e.name ILIKE $1 OR e.specialty ILIKE $1 OR e.email ILIKE $1)';
        countParams.push(`%${search}%`);
      }
      if (isActive !== undefined) {
        countQuery += ` AND e.is_active = $${countParams.length + 1}`;
        countParams.push(isActive === 'true');
      }

      const countResult = await query(countQuery, countParams);
      const totalExperts = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          experts: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalExperts,
            pages: Math.ceil(totalExperts / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get experts error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch experts.',
      });
    }
  }

  // Get expert by ID
  async getExpertById(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        `SELECT e.*, 
                COALESCE(
                  (SELECT json_agg(json_build_object(
                    'id', s.id,
                    'name', s.name,
                    'price', s.price
                  ))
                  FROM services s
                  JOIN expert_services es ON s.id = es.service_id
                  WHERE es.expert_id = e.id AND s.is_active = TRUE), '[]'
                ) as services
         FROM experts e
         WHERE e.id = $1`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Expert not found.',
        });
      }

      res.json({
        success: true,
        data: { expert: result.rows[0] },
      });
    } catch (error) {
      console.error('Get expert error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch expert.',
      });
    }
  }

  // Create expert (Admin only)
  async createExpert(req, res) {
    try {
      const { name, email, phone, specialty, bio, imageUrl, serviceIds } = req.body;

      const expertResult = await transaction(async (client) => {
        const result = await client.query(
          `INSERT INTO experts (name, email, phone, specialty, bio, image_url)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING *`,
          [name, email || null, phone || null, specialty || null, bio || null, imageUrl || null]
        );

        const expertId = result.rows[0].id;

        if (serviceIds && Array.isArray(serviceIds) && serviceIds.length > 0) {
          for (const serviceId of serviceIds) {
            await client.query(
              'INSERT INTO expert_services (expert_id, service_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
              [expertId, serviceId]
            );
          }
        }

        const expertRes = await client.query(
          `SELECT e.*, 
                  COALESCE(
                    (SELECT json_agg(json_build_object('id', s.id, 'name', s.name))
                     FROM services s
                     JOIN expert_services es ON s.id = es.service_id
                     WHERE es.expert_id = e.id), '[]'
                  ) as services
           FROM experts e
           WHERE e.id = $1`,
          [expertId]
        );
        return expertRes.rows[0];
      });

      res.status(201).json({
        success: true,
        message: 'Expert created successfully.',
        data: { expert: expertResult },
      });
    } catch (error) {
      console.error('Create expert error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to create expert.',
      });
    }
  }

  // Update expert (Admin only)
  async updateExpert(req, res) {
    try {
      const { id } = req.params;
      const { name, email, phone, specialty, bio, imageUrl, isActive, serviceIds } = req.body;

      const expertResult = await transaction(async (client) => {
        const result = await client.query(
          `UPDATE experts 
           SET name = COALESCE($1, name),
               email = COALESCE($2, email),
               phone = COALESCE($3, phone),
               specialty = COALESCE($4, specialty),
               bio = COALESCE($5, bio),
               image_url = COALESCE($6, image_url),
               is_active = COALESCE($7, is_active),
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $8
           RETURNING *`,
          [name, email, phone, specialty, bio, imageUrl, isActive, id]
        );

        if (result.rows.length === 0) {
          const err = new Error('Expert not found.');
          err.code = 'NOT_FOUND';
          throw err;
        }

        if (serviceIds !== undefined) {
          await client.query('DELETE FROM expert_services WHERE expert_id = $1', [id]);

          if (Array.isArray(serviceIds) && serviceIds.length > 0) {
            for (const serviceId of serviceIds) {
              await client.query(
                'INSERT INTO expert_services (expert_id, service_id) VALUES ($1, $2)',
                [id, serviceId]
              );
            }
          }
        }

        const expertRes = await client.query(
          `SELECT e.*, 
                  COALESCE(
                    (SELECT json_agg(json_build_object('id', s.id, 'name', s.name))
                     FROM services s
                     JOIN expert_services es ON s.id = es.service_id
                     WHERE es.expert_id = e.id), '[]'
                  ) as services
           FROM experts e
           WHERE e.id = $1`,
          [id]
        );
        return expertRes.rows[0];
      });

      res.json({
        success: true,
        message: 'Expert updated successfully.',
        data: { expert: expertResult },
      });
    } catch (error) {
      if (error.code === 'NOT_FOUND') {
        return res.status(404).json({
          success: false,
          message: 'Expert not found.',
        });
      }
      console.error('Update expert error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to update expert.',
      });
    }
  }

  // Delete expert (Admin only - soft delete)
  async deleteExpert(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        'UPDATE experts SET is_active = FALSE WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Expert not found.',
        });
      }

      res.json({
        success: true,
        message: 'Expert deleted successfully.',
      });
    } catch (error) {
      console.error('Delete expert error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete expert.',
      });
    }
  }
}

module.exports = new ExpertsController();
