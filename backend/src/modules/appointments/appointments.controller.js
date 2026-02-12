const { query } = require('../../config/db');
const emailService = require('../auth/auth.service.email');

class AppointmentsController {
  // Create appointment
  // Create appointment
  async createAppointment(req, res) {
    try {
      const {
        serviceId,
        expertId,
        customerName,
        customerPhone,
        customerEmail,
        appointmentDate,
        appointmentTime,
        notes,
        payNow,
        paymentMethod,
        offerId,
      } = req.body;

      // 1. Get service details for pricing
      const serviceResult = await query(
        'SELECT id, name, price FROM services WHERE id = $1 AND is_active = TRUE',
        [serviceId]
      );

      if (serviceResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Service not found.' });
      }

      const service = serviceResult.rows[0];
      let totalPrice = parseFloat(service.price) || 0;

      // Apply offer discount if valid offerId provided
      let appliedOfferId = null;
      if (offerId) {
        const offerResult = await query(
          `SELECT id, title, discount_percentage, discount_amount, service_id, start_date, end_date, is_active
           FROM offers WHERE id = $1 AND is_active = TRUE
           AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE`,
          [offerId]
        );
        if (offerResult.rows.length > 0) {
          const offer = offerResult.rows[0];
          const offerServiceId = offer.service_id?.toString();
          if (!offerServiceId || offerServiceId === serviceId) {
            appliedOfferId = offer.id;
            if (offer.discount_percentage != null) {
              totalPrice = totalPrice * (1 - parseFloat(offer.discount_percentage) / 100);
            } else if (offer.discount_amount != null) {
              totalPrice = Math.max(0, totalPrice - parseFloat(offer.discount_amount));
            }
            totalPrice = Math.round(totalPrice * 100) / 100;
          }
        }
      }

      // 2. Logic for Status & Expiration
      let status = 'reserved';
      let paymentStatus = 'unpaid';
      let paidAt = null;
      let expiresAt = null;

      if (payNow === true || payNow === 'true') { // Handling both boolean and string bools
        status = 'confirmed';
        paymentStatus = 'paid';
        paidAt = new Date();
      } else {
        expiresAt = new Date(Date.now() + 4 * 60 * 60 * 1000); // 4-hour window
      }

      // 3. Create appointment
      const result = await query(
        `INSERT INTO appointments (
          user_id, service_id, expert_id, customer_name, customer_phone, 
          customer_email, appointment_date, appointment_time, status, 
          payment_status, payment_method, total_price, notes, expires_at, paid_at, offer_id
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        RETURNING *`,
        [
          req.user.id,
          serviceId,
          expertId || null,
          customerName,
          customerPhone,
          customerEmail,
          appointmentDate,
          appointmentTime,
          status,
          paymentStatus,
          paymentMethod || null,
          totalPrice,
          notes || '',
          expiresAt,
          paidAt,
          appliedOfferId,
        ]
      );

      const appointment = result.rows[0];


      // 1. Send the response to Flutter immediately
      res.status(201).json({
        success: true,
        message: payNow ? 'Appointment confirmed!' : 'Reserved. Pay within 4 hours.',
        data: { appointment },
      });

      // 2. Run these in the background (Remove 'await' for the email)
      if (status === 'confirmed') {
        emailService.sendAppointmentConfirmation(customerEmail, {
          customerName,
          serviceName: service.name,
          date: appointmentDate,
          time: appointmentTime,
          price: totalPrice,
        }).catch(err => console.error("Email failed in background:", err));
      }

      // WebSocket logic
      if (global.io) {
        global.io.to('admin').emit('appointment-created', { appointment });
        global.io.emit('appointments-updated', { type: 'created', appointment });
      }

    } catch (error) {
      console.error('❌ Create appointment error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }

  // Get user appointments
  async getUserAppointments(req, res) {
    try {
      const { status } = req.query;

      let queryText = `
        SELECT a.*, s.name as service_name, s.duration, 
               e.name as expert_name, e.image_url as expert_image
        FROM appointments a
        LEFT JOIN services s ON a.service_id = s.id
        LEFT JOIN experts e ON a.expert_id = e.id
        WHERE a.user_id = $1
      `;
      const queryParams = [req.user.id];

      if (status) {
        queryText += ' AND a.status = $2';
        queryParams.push(status);
      }

      queryText += ' ORDER BY a.appointment_date DESC, a.appointment_time DESC';

      const result = await query(queryText, queryParams);

      res.json({
        success: true,
        data: { appointments: result.rows },
      });
    } catch (error) {
      console.error('Get user appointments error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch appointments.',
      });
    }
  }

  // Get all appointments (Admin only)
  async getAllAppointments(req, res) {
    try {
      const { status, date, page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = `
        SELECT a.*, s.name as service_name, s.duration,
               e.name as expert_name, u.name as user_name, u.email as user_email,
               o.title as offer_title, o.id as offer_id
        FROM appointments a
        LEFT JOIN services s ON a.service_id = s.id
        LEFT JOIN experts e ON a.expert_id = e.id
        LEFT JOIN users u ON a.user_id = u.id
        LEFT JOIN offers o ON a.offer_id = o.id
        WHERE 1=1
      `;
      const queryParams = [];
      let paramCounter = 1;

      if (status) {
        queryText += ` AND a.status = $${paramCounter}`;
        queryParams.push(status);
        paramCounter++;
      }

      if (date) {
        queryText += ` AND a.appointment_date = $${paramCounter}`;
        queryParams.push(date);
        paramCounter++;
      }

      queryText += ` ORDER BY a.appointment_date DESC, a.appointment_time DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      const countResult = await query(
        'SELECT COUNT(*) FROM appointments WHERE 1=1' +
          (status ? ' AND status = $1' : '') +
          (date ? ` AND appointment_date = $${status ? 2 : 1}` : ''),
        status && date ? [status, date] : status ? [status] : date ? [date] : []
      );

      res.json({
        success: true,
        data: {
          appointments: result.rows,
          pagination: {
            total: parseInt(countResult.rows[0].count),
            page: parseInt(page),
            limit: parseInt(limit),
          },
        },
      });
    } catch (error) {
      console.error('Get all appointments error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch appointments.',
      });
    }
  }

  // Update appointment status (Admin only)
  async updateAppointmentStatus(req, res) {
    try {
      const { id } = req.params;
      const { status, cancelReason } = req.body;

      let queryText = 'UPDATE appointments SET status = $1';
      const queryParams = [status];
      let paramCounter = 2;

      if (status === 'cancelled') {
        queryText += `, cancelled_at = CURRENT_TIMESTAMP, cancelled_reason = $${paramCounter}`;
        queryParams.push(cancelReason || 'Cancelled by admin');
        paramCounter++;
      }

      queryText += ` WHERE id = $${paramCounter} RETURNING *`;
      queryParams.push(id);

      const result = await query(queryText, queryParams);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found.',
        });
      }

      // Emit WebSocket events
      if (global.io) {
        global.io.to('admin').emit('appointment-updated', { appointment: result.rows[0] });
        global.io.emit('appointments-updated', { type: 'updated', appointment: result.rows[0] });
      }

      res.json({
        success: true,
        message: 'Appointment status updated successfully.',
        data: { appointment: result.rows[0] },
      });
    } catch (error) {
      console.error('Update appointment status error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update appointment status.',
      });
    }
  }

  // Mark appointment as paid
  async markAsPaid(req, res) {
    try {
      const { id } = req.params;
      const { paymentMethod } = req.body;

      const result = await query(
        `UPDATE appointments 
         SET payment_status = 'paid', 
             status = 'confirmed',
             paid_at = CURRENT_TIMESTAMP,
             payment_method = $1,
             expires_at = NULL
         WHERE id = $2 AND payment_status = 'unpaid'
         RETURNING *`,
        [paymentMethod, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found or already paid.',
        });
      }

      // Emit WebSocket events
      if (global.io) {
        global.io.to('admin').emit('appointment-updated', { appointment: result.rows[0] });
        global.io.emit('appointments-updated', { type: 'paid', appointment: result.rows[0] });
      }

      res.json({
        success: true,
        message: 'Payment recorded successfully.',
        data: { appointment: result.rows[0] },
      });
    } catch (error) {
      console.error('Mark as paid error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to record payment.',
      });
    }
  }

  // Cancel appointment
  async cancelAppointment(req, res) {
    try {
      const { id } = req.params;
      const { reason } = req.body;

      const canManageAll = (req.user.permissions || []).includes('appointments.manage_all');

      let queryText = 'SELECT * FROM appointments WHERE id = $1';
      const queryParams = [id];

      if (!canManageAll) {
        queryText += ' AND user_id = $2';
        queryParams.push(req.user.id);
      }

      const checkResult = await query(queryText, queryParams);

      if (checkResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found.',
        });
      }

      const appointment = checkResult.rows[0];

      if (appointment.status === 'cancelled' || appointment.status === 'completed') {
        return res.status(400).json({
          success: false,
          message: `Cannot cancel an appointment that is ${appointment.status}.`,
        });
      }

      const result = await query(
        `UPDATE appointments 
         SET status = 'cancelled', 
             cancelled_at = CURRENT_TIMESTAMP,
             cancelled_reason = $1
         WHERE id = $2
         RETURNING *`,
        [reason || 'Cancelled by user', id]
      );

      // Emit WebSocket events
      if (global.io) {
        global.io.to('admin').emit('appointment-updated', { appointment: result.rows[0] });
        global.io.emit('appointments-updated', { type: 'cancelled', appointment: result.rows[0] });
      }

      res.json({
        success: true,
        message: 'Appointment cancelled successfully.',
        data: { appointment: result.rows[0] },
      });
    } catch (error) {
      console.error('Cancel appointment error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to cancel appointment.',
      });
    }
  }

  // Delete appointment (Admin only)
  async deleteAppointment(req, res) {
    try {
      const { id } = req.params;

      // Check if appointment exists
      const checkResult = await query(
        'SELECT * FROM appointments WHERE id = $1',
        [id]
      );

      if (checkResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Appointment not found.',
        });
      }

      const appointment = checkResult.rows[0];

      // Delete the appointment
      await query('DELETE FROM appointments WHERE id = $1', [id]);

      // Emit WebSocket events
      if (global.io) {
        global.io.to('admin').emit('appointment-deleted', { appointmentId: id });
        global.io.emit('appointments-updated', { type: 'deleted', appointmentId: id, appointment });
      }

      res.json({
        success: true,
        message: 'Appointment deleted successfully.',
        data: { appointmentId: id },
      });
    } catch (error) {
      console.error('Delete appointment error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete appointment.',
      });
    }
  }

  // Get dashboard statistics (Admin only)
  async getDashboardStats(req, res) {
    try {
      const statsResult = await query(`
        SELECT 
          COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_count,
          COUNT(*) FILTER (WHERE status = 'reserved') as reserved_count,
          COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
          COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
          COUNT(*) FILTER (WHERE appointment_date = CURRENT_DATE) as today_count,
          COUNT(*) as total_appointments,
          COALESCE(SUM(total_price) FILTER (WHERE payment_status = 'paid'), 0) + COALESCE(SUM(total_price) FILTER (WHERE status = 'confirmed' AND payment_status != 'paid'), 0) as total_revenue,
          COALESCE(SUM(total_price) FILTER (WHERE payment_status = 'paid' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)), 0) + COALESCE(SUM(total_price) FILTER (WHERE status = 'confirmed' AND payment_status != 'paid' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)), 0) as monthly_revenue
        FROM appointments
      `);
      const customersResult = await query(
        `SELECT COUNT(*) as total_customers FROM users u
         JOIN roles r ON u.role_id = r.id
         WHERE r.name = 'Customer'`
      );
      res.json({
        success: true,
        data: {
          stats: {
            ...statsResult.rows[0],
            total_customers: customersResult.rows[0].total_customers
          }
        },
      });
    } catch (error) {
      console.error('Get dashboard stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch dashboard statistics.',
      });
    }
  }

  // Recent appointments for dashboard
  async getRecentAppointments(req, res) {
    try {
      const result = await query(
        `SELECT a.id, a.customer_name, a.customer_email, a.appointment_date, a.appointment_time, a.status,
                a.offer_id, o.title as offer_title, s.name as service_name
         FROM appointments a
         JOIN services s ON a.service_id = s.id
         LEFT JOIN offers o ON a.offer_id = o.id
         ORDER BY a.appointment_date DESC, a.appointment_time DESC
         LIMIT 10`
      );
      res.json({ appointments: result.rows });
    } catch (error) {
      console.error('❌ Get recent appointments error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  }
}

module.exports = new AppointmentsController();
