const { query } = require('../../config/db');

/**
 * Reports & Sales API
 * Provides sales data, revenue reports, and transaction history
 */
class ReportsController {
  /**
   * Get sales overview - today, this week, this month revenue + recent transactions
   */
  async getSalesOverview(req, res) {
    try {
      const [todayResult, weekResult, monthResult, transactionsResult] = await Promise.all([
        query(`
          SELECT COALESCE(SUM(total_price), 0) as revenue, COUNT(*) as count
          FROM appointments
          WHERE payment_status = 'paid' AND appointment_date = CURRENT_DATE
        `),
        query(`
          SELECT COALESCE(SUM(total_price), 0) as revenue, COUNT(*) as count
          FROM appointments
          WHERE payment_status = 'paid'
            AND appointment_date >= CURRENT_DATE - INTERVAL '7 days'
        `),
        query(`
          SELECT COALESCE(SUM(total_price), 0) as revenue, COUNT(*) as count
          FROM appointments
          WHERE payment_status = 'paid'
            AND appointment_date >= DATE_TRUNC('month', CURRENT_DATE)::date
        `),
        query(`
          SELECT a.id, a.customer_name, a.customer_email, a.appointment_date, a.appointment_time,
                 a.total_price, a.payment_status, a.payment_method, a.paid_at, a.created_at,
                 s.name as service_name, e.name as expert_name
          FROM appointments a
          LEFT JOIN services s ON a.service_id = s.id
          LEFT JOIN experts e ON a.expert_id = e.id
          WHERE a.payment_status = 'paid'
          ORDER BY a.paid_at DESC NULLS LAST, a.created_at DESC
          LIMIT 50
        `),
      ]);

      res.json({
        success: true,
        data: {
          today: {
            revenue: parseFloat(todayResult.rows[0]?.revenue || 0),
            count: parseInt(todayResult.rows[0]?.count || 0),
          },
          week: {
            revenue: parseFloat(weekResult.rows[0]?.revenue || 0),
            count: parseInt(weekResult.rows[0]?.count || 0),
          },
          month: {
            revenue: parseFloat(monthResult.rows[0]?.revenue || 0),
            count: parseInt(monthResult.rows[0]?.count || 0),
          },
          transactions: transactionsResult.rows,
        },
      });
    } catch (error) {
      console.error('Get sales overview error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch sales overview.',
      });
    }
  }

  /**
   * Get reports with date range - revenue chart data, appointments summary, top services
   */
  async getReports(req, res) {
    try {
      let startDate = req.query.startDate;
      let endDate = req.query.endDate;

      const now = new Date();
      if (!endDate) {
        endDate = now.toISOString().split('T')[0];
      }
      if (!startDate) {
        const d = new Date(now);
        d.setDate(d.getDate() - 30);
        startDate = d.toISOString().split('T')[0];
      }

      const [revenueByDayResult, summaryResult, topServicesResult, appointmentsByStatusResult] = await Promise.all([
        query(`
          SELECT appointment_date as date, COALESCE(SUM(total_price), 0) as revenue, COUNT(*) as count
          FROM appointments
          WHERE payment_status = 'paid'
            AND appointment_date >= $1 AND appointment_date <= $2
          GROUP BY appointment_date
          ORDER BY appointment_date ASC
        `, [startDate, endDate]),
        query(`
          SELECT
            COUNT(*) as total_appointments,
            COUNT(*) FILTER (WHERE payment_status = 'paid') as paid_count,
            COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
            COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_count,
            COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
            COALESCE(SUM(total_price) FILTER (WHERE payment_status = 'paid'), 0) as total_revenue
          FROM appointments
          WHERE appointment_date >= $1 AND appointment_date <= $2
        `, [startDate, endDate]),
        query(`
          SELECT s.name, COUNT(*) as bookings, COALESCE(SUM(a.total_price), 0) as revenue
          FROM appointments a
          JOIN services s ON a.service_id = s.id
          WHERE a.payment_status = 'paid'
            AND a.appointment_date >= $1 AND a.appointment_date <= $2
          GROUP BY s.id, s.name
          ORDER BY revenue DESC
          LIMIT 10
        `, [startDate, endDate]),
        query(`
          SELECT status, COUNT(*) as count
          FROM appointments
          WHERE appointment_date >= $1 AND appointment_date <= $2
          GROUP BY status
        `, [startDate, endDate]),
      ]);

      const revenueData = revenueByDayResult.rows.map((r) => ({
        date: r.date,
        day: r.date ? new Date(r.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: '2-digit' }) : '',
        revenue: parseFloat(r.revenue),
        count: parseInt(r.count),
      }));

      res.json({
        success: true,
        data: {
          startDate,
          endDate,
          revenueData,
          summary: {
            totalAppointments: parseInt(summaryResult.rows[0]?.total_appointments || 0),
            paidCount: parseInt(summaryResult.rows[0]?.paid_count || 0),
            completedCount: parseInt(summaryResult.rows[0]?.completed_count || 0),
            confirmedCount: parseInt(summaryResult.rows[0]?.confirmed_count || 0),
            cancelledCount: parseInt(summaryResult.rows[0]?.cancelled_count || 0),
            totalRevenue: parseFloat(summaryResult.rows[0]?.total_revenue || 0),
          },
          topServices: topServicesResult.rows.map((r) => ({
            name: r.name,
            bookings: parseInt(r.bookings),
            revenue: parseFloat(r.revenue),
          })),
          appointmentsByStatus: appointmentsByStatusResult.rows.map((r) => ({
            status: r.status,
            count: parseInt(r.count),
          })),
        },
      });
    } catch (error) {
      console.error('Get reports error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reports.',
      });
    }
  }

  /**
   * Get transactions (paid appointments) with optional date range and pagination
   */
  async getTransactions(req, res) {
    try {
      const { startDate, endDate, page = 1, limit = 50 } = req.query;
      const offset = (page - 1) * limit;

      let whereClause = 'WHERE a.payment_status = \'paid\'';
      const params = [];
      let paramCounter = 1;

      if (startDate) {
        whereClause += ` AND a.appointment_date >= $${paramCounter++}`;
        params.push(startDate);
      }
      if (endDate) {
        whereClause += ` AND a.appointment_date <= $${paramCounter++}`;
        params.push(endDate);
      }

      const dataParams = [...params];
      dataParams.push(limit, offset);

      const result = await query(
        `SELECT a.id, a.customer_name, a.customer_email, a.appointment_date, a.appointment_time,
                a.total_price, a.payment_status, a.payment_method, a.paid_at, a.created_at,
                s.name as service_name, e.name as expert_name
         FROM appointments a
         LEFT JOIN services s ON a.service_id = s.id
         LEFT JOIN experts e ON a.expert_id = e.id
         ${whereClause}
         ORDER BY a.paid_at DESC NULLS LAST, a.created_at DESC
         LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`,
        dataParams
      );

      const countResult = await query(
        `SELECT COUNT(*) FROM appointments a ${whereClause}`,
        params
      );
      const total = parseInt(countResult.rows[0]?.count || 0);

      res.json({
        success: true,
        data: {
          transactions: result.rows,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get transactions error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch transactions.',
      });
    }
  }
}

module.exports = new ReportsController();
