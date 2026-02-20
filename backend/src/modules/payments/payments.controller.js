const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { query } = require('../../config/db');
const emailService = require('../auth/auth.service.email');

class PaymentsController {
  // Create PaymentIntent with booking metadata for webhook verification
  createPaymentIntent = async (req, res) => {
    try {
      const {
        amount,
        currency,
        serviceId,
        appointmentDate,
        appointmentTime,
        customerName,
        customerEmail,
        customerPhone,
        offerId,
      } = req.body;

      const metadata = {
        userId: req.user.id,
        serviceId: String(serviceId || ''),
        appointmentDate: String(appointmentDate || ''),
        appointmentTime: String(appointmentTime || ''),
        customerName: String(customerName || ''),
        customerEmail: String(customerEmail || ''),
        customerPhone: String(customerPhone || ''),
        offerId: String(offerId || ''),
      };

      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: currency || 'pkr',
        metadata,
      });

      res.status(200).json({
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  };

  // Stripe webhook - verifies payment and creates appointment server-side
  handleWebhook = async (req, res) => {
    console.log('📥 Stripe webhook received');
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      console.error('❌ STRIPE_WEBHOOK_SECRET not configured – add it to .env and configure webhook in Stripe Dashboard');
      return res.status(500).send('Webhook secret not configured');
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
      console.error('❌ Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    console.log('📥 Webhook event type:', event.type);

    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object;
      try {
        await this._handlePaymentSucceeded(paymentIntent);
      } catch (err) {
        console.error('❌ Webhook: failed to create appointment:', err.message);
        console.error('   Stack:', err.stack);
        return res.status(500).json({ received: false, error: err.message });
      }
    }

    res.json({ received: true });
  };

  async _handlePaymentSucceeded(paymentIntent) {
    const { id: paymentIntentId, metadata } = paymentIntent;

    // Idempotency: skip if we already created this appointment
    const existing = await query(
      'SELECT id FROM appointments WHERE payment_intent_id = $1',
      [paymentIntentId]
    );
    if (existing.rows.length > 0) {
      console.log('✅ Webhook: appointment already created for', paymentIntentId);
      return;
    }

    const {
      userId,
      serviceId,
      appointmentDate,
      appointmentTime,
      customerName,
      customerEmail,
      customerPhone,
      offerId,
    } = metadata;

    if (!userId || !serviceId || !appointmentDate || !appointmentTime) {
      console.error('❌ Webhook: missing required metadata', metadata);
      return;
    }

    try {
      // Get service and apply offer
      const serviceResult = await query(
        'SELECT id, name, price FROM services WHERE id = $1 AND is_active = TRUE',
        [serviceId]
      );
      if (serviceResult.rows.length === 0) {
        console.error('❌ Webhook: service not found', serviceId);
        return;
      }

      const service = serviceResult.rows[0];
      let totalPrice = parseFloat(service.price) || 0;
      let appliedOfferId = null;

      if (offerId) {
        const offerResult = await query(
          `SELECT id, discount_percentage, discount_amount, service_id, apply_to
           FROM offers WHERE id = $1 AND is_active = TRUE
           AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE`,
          [offerId]
        );
        if (offerResult.rows.length > 0) {
          const offer = offerResult.rows[0];
          const applyTo = offer.apply_to || (offer.service_id ? 'service' : 'all');
          if (applyTo === 'all_courses' || applyTo === 'course') {
            // Offer is for courses only, skip for service booking
          } else {
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
      }

      const result = await query(
        `INSERT INTO appointments (
          user_id, service_id, customer_name, customer_phone, customer_email,
          appointment_date, appointment_time, status, payment_status, payment_method,
          total_price, notes, paid_at, payment_intent_id, offer_id
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed', 'paid', 'online', $8, '', CURRENT_TIMESTAMP, $9, $10)
        RETURNING *`,
        [
          userId,
          serviceId,
          customerName || 'Customer',
          customerPhone || '',
          customerEmail || '',
          appointmentDate,
          appointmentTime,
          totalPrice,
          paymentIntentId,
          appliedOfferId,
        ]
      );

      const appointment = result.rows[0];
      console.log('✅ Webhook: created appointment', appointment.id, 'for payment', paymentIntentId, '- will appear in admin-web');

      // Email confirmation (only if customer has email)
      if (customerEmail && String(customerEmail).trim()) {
        emailService.sendAppointmentConfirmation(customerEmail, {
          customerName: customerName || 'Customer',
          serviceName: service.name,
          date: appointmentDate,
          time: appointmentTime,
          price: totalPrice,
        }).catch(err => console.error('❌ Webhook: Email failed:', err.message));
      }

      // WebSocket
      if (global.io) {
        global.io.to('admin').emit('appointment-created', { appointment });
        global.io.emit('appointments-updated', { type: 'created', appointment });
      }

      // Push notification to customer
      const pushService = require('../../services/pushNotificationService');
      pushService.sendToUser(userId, {
        title: 'Appointment Confirmed',
        body: `Your appointment for ${service.name} on ${appointmentDate} is confirmed!`,
        data: { type: 'appointment', id: appointment.id },
      }).catch(err => console.error('❌ Webhook: Push to customer failed:', err.message));
      pushService.sendToAdmins({
        title: 'New Booking',
        body: `${customerName || 'Customer'} booked ${service.name} for ${appointmentDate} (paid)`,
        data: { type: 'appointment', id: appointment.id },
      }).catch(() => {});
    } catch (err) {
      console.error('❌ Webhook: failed to create appointment', err);
      throw err;
    }
  }

  // Client-side fallback: when app confirms payment, create appointment if webhook hasn't
  confirmAppointment = async (req, res) => {
    try {
      const { paymentIntentId } = req.body;
      if (!paymentIntentId) {
        return res.status(400).json({ success: false, message: 'paymentIntentId required' });
      }

      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (paymentIntent.status !== 'succeeded') {
        return res.status(400).json({
          success: false,
          message: `Payment not completed (status: ${paymentIntent.status})`,
        });
      }

      await this._handlePaymentSucceeded(paymentIntent);
      const result = await query(
        'SELECT id FROM appointments WHERE payment_intent_id = $1',
        [paymentIntentId]
      );
      res.json({
        success: true,
        message: 'Appointment created',
        data: { appointmentId: result.rows[0]?.id },
      });
    } catch (err) {
      console.error('❌ confirmAppointment error:', err.message);
      res.status(500).json({ success: false, message: err.message });
    }
  };

  getRecentPayments = async (req, res) => {
    try {
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