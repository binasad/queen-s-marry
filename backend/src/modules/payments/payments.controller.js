const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

class PaymentsController {
  // Use arrow functions to avoid "this" binding issues
  createPaymentIntent = async (req, res) => {
    try {
      const { amount, currency } = req.body;
      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: currency || 'pkr',
      });

      res.status(200).json({
        success: true,
        clientSecret: paymentIntent.client_secret,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  getRecentPayments = async (req, res) => {
    try {
      const { query } = require('../../config/db');
      const result = await query(
        `SELECT a.id, a.customer_name, a.total_price, a.payment_status, a.paid_at, a.created_at,
                a.offer_id, o.title as offer_title
         FROM appointments a
         LEFT JOIN offers o ON a.offer_id = o.id
         WHERE a.payment_status = 'paid'
         ORDER BY a.paid_at DESC NULLS LAST, a.created_at DESC LIMIT 5`
      );
      res.json({ success: true, payments: result.rows });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}

// ⚠️ THIS LINE IS THE KEY: You must export the instance (new ...)
module.exports = new PaymentsController();