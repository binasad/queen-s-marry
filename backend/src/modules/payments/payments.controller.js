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
        `SELECT id, customer_name, total_price, payment_status, paid_at, created_at
         FROM appointments
         WHERE payment_status = 'paid'
         ORDER BY paid_at DESC LIMIT 5`
      );
      res.json({ success: true, payments: result.rows });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
}

// ⚠️ THIS LINE IS THE KEY: You must export the instance (new ...)
module.exports = new PaymentsController();