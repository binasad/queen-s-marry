const { query } = require('../../config/db');

class SupportController {
  // Get all support tickets
  async getAllTickets(req, res) {
    try {
      const { status, priority, search, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = `
        SELECT t.*, 
               u.name as user_name,
               u.email as user_email,
               a.name as assigned_to_name
        FROM support_tickets t
        LEFT JOIN users u ON t.user_id = u.id
        LEFT JOIN users a ON t.assigned_to = a.id
        WHERE 1=1
      `;
      const queryParams = [];
      let paramCounter = 1;

      if (status) {
        queryText += ` AND t.status = $${paramCounter}`;
        queryParams.push(status);
        paramCounter++;
      }

      if (priority) {
        queryText += ` AND t.priority = $${paramCounter}`;
        queryParams.push(priority);
        paramCounter++;
      }

      if (search) {
        queryText += ` AND (t.subject ILIKE $${paramCounter} OR t.message ILIKE $${paramCounter} OR t.customer_name ILIKE $${paramCounter} OR t.customer_email ILIKE $${paramCounter})`;
        queryParams.push(`%${search}%`);
        paramCounter++;
      }

      queryText += ` ORDER BY 
        CASE t.priority
          WHEN 'urgent' THEN 1
          WHEN 'high' THEN 2
          WHEN 'medium' THEN 3
          WHEN 'low' THEN 4
        END,
        t.created_at DESC
        LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM support_tickets t WHERE 1=1';
      const countParams = [];
      if (status) {
        countQuery += ' AND t.status = $1';
        countParams.push(status);
      }
      if (priority) {
        countQuery += ` AND t.priority = $${countParams.length + 1}`;
        countParams.push(priority);
      }
      if (search) {
        countQuery += ` AND (t.subject ILIKE $${countParams.length + 1} OR t.message ILIKE $${countParams.length + 1} OR t.customer_name ILIKE $${countParams.length + 1} OR t.customer_email ILIKE $${countParams.length + 1})`;
        countParams.push(`%${search}%`);
      }

      const countResult = await query(countQuery, countParams);
      const totalTickets = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          tickets: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalTickets,
            pages: Math.ceil(totalTickets / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get tickets error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch support tickets.',
      });
    }
  }

  // Get ticket by ID
  async getTicketById(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        `SELECT t.*, 
               u.name as user_name,
               u.email as user_email,
               a.name as assigned_to_name
        FROM support_tickets t
        LEFT JOIN users u ON t.user_id = u.id
        LEFT JOIN users a ON t.assigned_to = a.id
        WHERE t.id = $1`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found.',
        });
      }

      res.json({
        success: true,
        data: { ticket: result.rows[0] },
      });
    } catch (error) {
      console.error('Get ticket error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch ticket.',
      });
    }
  }

  // Create ticket (public or authenticated)
  async createTicket(req, res) {
    try {
      const { customerName, customerEmail, customerPhone, subject, message, userId } = req.body;

      const result = await query(
        `INSERT INTO support_tickets (user_id, customer_name, customer_email, customer_phone, subject, message)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [userId || null, customerName, customerEmail, customerPhone || null, subject, message]
      );

      res.status(201).json({
        success: true,
        message: 'Support ticket created successfully.',
        data: { ticket: result.rows[0] },
      });
    } catch (error) {
      console.error('Create ticket error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create support ticket.',
      });
    }
  }

  // Update ticket (Admin only)
  async updateTicket(req, res) {
    try {
      const { id } = req.params;
      const { status, priority, assignedTo, response } = req.body;

      const updateFields = [];
      const updateValues = [];
      let paramCounter = 1;

      if (status) {
        updateFields.push(`status = $${paramCounter}`);
        updateValues.push(status);
        paramCounter++;
      }

      if (priority) {
        updateFields.push(`priority = $${paramCounter}`);
        updateValues.push(priority);
        paramCounter++;
      }

      if (assignedTo !== undefined) {
        updateFields.push(`assigned_to = $${paramCounter}`);
        updateValues.push(assignedTo || null);
        paramCounter++;
      }

      if (response !== undefined) {
        updateFields.push(`response = $${paramCounter}`);
        updateValues.push(response || null);
        paramCounter++;
      }

      if (status === 'resolved' || status === 'closed') {
        updateFields.push(`resolved_at = CURRENT_TIMESTAMP`);
      }

      if (updateFields.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No fields to update.',
        });
      }

      updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
      updateValues.push(id);

      const result = await query(
        `UPDATE support_tickets 
         SET ${updateFields.join(', ')}
         WHERE id = $${paramCounter}
         RETURNING *`,
        updateValues
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found.',
        });
      }

      res.json({
        success: true,
        message: 'Ticket updated successfully.',
        data: { ticket: result.rows[0] },
      });
    } catch (error) {
      console.error('Update ticket error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update ticket.',
      });
    }
  }

  // Delete ticket (Admin only)
  async deleteTicket(req, res) {
    try {
      const { id } = req.params;

      const result = await query('DELETE FROM support_tickets WHERE id = $1 RETURNING id', [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found.',
        });
      }

      res.json({
        success: true,
        message: 'Ticket deleted successfully.',
      });
    } catch (error) {
      console.error('Delete ticket error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete ticket.',
      });
    }
  }
}

module.exports = new SupportController();
