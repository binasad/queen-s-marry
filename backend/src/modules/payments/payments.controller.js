const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { query } = require('../../config/db');
const emailService = require('../auth/auth.service.email');

// ---- Cart helpers (shared with JazzCash via duplication in jazzcash.controller) ----

// Normalize a client-supplied cartItems array into the canonical shape stored
// in payment metadata. Returns null when the array is unusable.
function normalizeCartItems(rawCart) {
  if (!Array.isArray(rawCart) || rawCart.length === 0) return null;
  const out = [];
  for (const raw of rawCart) {
    if (!raw || typeof raw !== 'object') continue;
    const sid = raw.serviceId ?? raw.sid;
    const date = raw.appointmentDate ?? raw.scheduledDate ?? raw.d;
    const time = raw.appointmentTime ?? raw.scheduledTime ?? raw.t;
    if (!sid || !date || !time) continue;
    out.push({
      serviceId: String(sid),
      appointmentDate: String(date),
      appointmentTime: String(time),
      offerId: raw.offerId ? String(raw.offerId) : '',
      unitPrice: raw.unitPrice != null ? Number(raw.unitPrice) : null,
    });
  }
  return out.length ? out : null;
}

// Encode a cart into Stripe metadata. Stripe limits each metadata value to 500
// chars and 50 keys total, so each item lives under its own `item_<i>` key.
function encodeCartIntoMetadata(cartItems, base = {}) {
  const metadata = { ...base, cartCount: String(cartItems.length) };
  cartItems.forEach((item, i) => {
    metadata[`item_${i}`] = JSON.stringify({
      sid: item.serviceId,
      d: item.appointmentDate,
      t: item.appointmentTime,
      oid: item.offerId || '',
      p: item.unitPrice != null ? item.unitPrice : null,
    });
  });
  return metadata;
}

// Inverse of `encodeCartIntoMetadata`. Returns null when no cart is encoded.
function decodeCartFromMetadata(metadata) {
  if (!metadata || !metadata.cartCount) return null;
  const count = parseInt(metadata.cartCount, 10);
  if (!Number.isFinite(count) || count <= 0) return null;
  const out = [];
  for (let i = 0; i < count; i++) {
    const raw = metadata[`item_${i}`];
    if (!raw) continue;
    try {
      const parsed = JSON.parse(raw);
      if (!parsed.sid || !parsed.d || !parsed.t) continue;
      out.push({
        serviceId: parsed.sid,
        appointmentDate: parsed.d,
        appointmentTime: parsed.t,
        offerId: parsed.oid || '',
        unitPrice: parsed.p != null ? Number(parsed.p) : null,
      });
    } catch (_) { /* ignore corrupt entry */ }
  }
  return out.length ? out : null;
}

// Resolve a service + offer pair into the actual price to charge. The offer
// must currently be active and applicable to this service (or to all services).
async function _resolvePricing(service, offerId) {
  let unitPrice = parseFloat(service.price) || 0;
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
      if (applyTo !== 'all_courses' && applyTo !== 'course') {
        const offerServiceId = offer.service_id?.toString();
        if (!offerServiceId || offerServiceId === service.id.toString()) {
          appliedOfferId = offer.id;
          if (offer.discount_percentage != null) {
            unitPrice = unitPrice * (1 - parseFloat(offer.discount_percentage) / 100);
          } else if (offer.discount_amount != null) {
            unitPrice = Math.max(0, unitPrice - parseFloat(offer.discount_amount));
          }
          unitPrice = Math.round(unitPrice * 100) / 100;
        }
      }
    }
  }
  return { unitPrice, appliedOfferId };
}

/// Create one appointment row per cart item and fire all the side effects
/// (email, WebSocket, customer push, admin push) for each. Used by both the
/// Stripe webhook and the JazzCash return handler.
///
/// Each appointment shares the same `payment_intent_id` (Stripe id or JazzCash
/// txnRefNo) so the idempotency check on the caller side ("any row for this
/// intent?") prevents double-processing on webhook retries.
async function createAppointmentsForPayment(opts) {
  const {
    items,
    userId,
    customerName,
    customerEmail,
    customerPhone,
    paymentIntentId,
    paymentMethod, // 'online' | 'jazzcash'
  } = opts;

  const pushService = require('../../services/pushNotificationService');
  const created = [];

  for (const item of items) {
    try {
      // Skip if a row for this exact (intent, service, date, time) already
      // exists — handles webhook retries and partial-failure replays without
      // double-booking.
      const dupCheck = await query(
        `SELECT id FROM appointments
         WHERE payment_intent_id = $1
           AND service_id = $2
           AND appointment_date = $3
           AND appointment_time = $4
         LIMIT 1`,
        [paymentIntentId, item.serviceId, item.appointmentDate, item.appointmentTime]
      );
      if (dupCheck.rows.length > 0) {
        console.log('⏭️  payments: skipping already-created appointment for', paymentIntentId, item.serviceId);
        continue;
      }

      const serviceResult = await query(
        'SELECT id, name, price FROM services WHERE id = $1 AND is_active = TRUE',
        [item.serviceId]
      );
      if (serviceResult.rows.length === 0) {
        console.error('❌ payments: service not found', item.serviceId);
        continue;
      }
      const service = serviceResult.rows[0];

      // Prefer the unitPrice the user actually saw at checkout (already
      // discount-adjusted); fall back to server-side recomputation.
      let unitPrice;
      let appliedOfferId = null;
      if (item.unitPrice != null && Number.isFinite(item.unitPrice)) {
        unitPrice = Math.round(item.unitPrice * 100) / 100;
        if (item.offerId) {
          // Still validate the offer so admin records reflect it; ignore the
          // pricing math since we trust the client-paid value.
          const offerCheck = await query(
            `SELECT id FROM offers WHERE id = $1 AND is_active = TRUE
             AND start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE`,
            [item.offerId]
          );
          if (offerCheck.rows.length > 0) appliedOfferId = offerCheck.rows[0].id;
        }
      } else {
        const pricing = await _resolvePricing(service, item.offerId);
        unitPrice = pricing.unitPrice;
        appliedOfferId = pricing.appliedOfferId;
      }

      const result = await query(
        `INSERT INTO appointments (
          user_id, service_id, customer_name, customer_phone, customer_email,
          appointment_date, appointment_time, status, payment_status, payment_method,
          total_price, notes, paid_at, payment_intent_id, offer_id
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed', 'paid', $8, $9, '', CURRENT_TIMESTAMP, $10, $11)
        RETURNING *`,
        [
          userId,
          item.serviceId,
          customerName || 'Customer',
          customerPhone || '',
          customerEmail || '',
          item.appointmentDate,
          item.appointmentTime,
          paymentMethod || 'online',
          unitPrice,
          paymentIntentId,
          appliedOfferId,
        ]
      );
      const appointment = result.rows[0];
      created.push({ appointment, service });
      console.log('✅ payments: created appointment', appointment.id, 'for', paymentIntentId);

      // --- Side effects (per appointment) ---
      if (customerEmail && String(customerEmail).trim()) {
        emailService.sendAppointmentConfirmation(customerEmail, {
          customerName: customerName || 'Customer',
          serviceName: service.name,
          date: item.appointmentDate,
          time: item.appointmentTime,
          price: unitPrice,
        }).catch(err => console.error('❌ payments: Email failed:', err.message));
      }

      if (global.io) {
        global.io.to('admin').emit('appointment-created', { appointment });
        global.io.emit('appointments-updated', { type: 'created', appointment });
      }

      pushService.sendToUser(userId, {
        title: 'Appointment Confirmed',
        body: `Your appointment for ${service.name} on ${item.appointmentDate} is confirmed!`,
        data: { type: 'appointment', id: appointment.id },
      }).catch(err => console.error('❌ payments: Push to customer failed:', err.message));
      pushService.sendToAdmins({
        title: 'New Booking',
        body: `${customerName || 'Customer'} booked ${service.name} for ${item.appointmentDate} (paid)`,
        data: { type: 'appointment', id: appointment.id },
      }).catch(() => {});
    } catch (err) {
      console.error('❌ payments: failed to materialise cart item', item, err);
      // Continue with the remaining items rather than aborting the whole cart.
    }
  }
  return created;
}

class PaymentsController {
  // Create PaymentIntent. Accepts either a single-service booking or a full
  // cartItems array; the webhook will create one appointment per cart item.
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
        cartItems,
      } = req.body;

      const baseMetadata = {
        userId: req.user.id,
        customerName: String(customerName || ''),
        customerEmail: String(customerEmail || ''),
        customerPhone: String(customerPhone || ''),
      };

      let metadata;
      const cart = normalizeCartItems(cartItems);
      if (cart) {
        metadata = encodeCartIntoMetadata(cart, baseMetadata);
      } else {
        metadata = {
          ...baseMetadata,
          serviceId: String(serviceId || ''),
          appointmentDate: String(appointmentDate || ''),
          appointmentTime: String(appointmentTime || ''),
          offerId: String(offerId || ''),
        };
      }

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

    const { userId, customerName, customerEmail, customerPhone } = metadata;
    if (!userId) {
      console.error('❌ Webhook: missing userId in metadata', metadata);
      return;
    }

    // Prefer the cart payload; fall back to the legacy single-service shape.
    let items = decodeCartFromMetadata(metadata);
    if (!items) {
      const { serviceId, appointmentDate, appointmentTime, offerId } = metadata;
      if (!serviceId || !appointmentDate || !appointmentTime) {
        console.error('❌ Webhook: missing required metadata', metadata);
        return;
      }
      items = [{
        serviceId, appointmentDate, appointmentTime,
        offerId: offerId || '', unitPrice: null,
      }];
    }

    // Idempotency: skip only when the full cart has already been materialised
    // for this payment. A partial result (e.g. a previous run crashed mid-loop)
    // should still be allowed to finish on retry.
    const existing = await query(
      'SELECT id FROM appointments WHERE payment_intent_id = $1',
      [paymentIntentId]
    );
    if (existing.rows.length >= items.length) {
      console.log('✅ Webhook: appointment(s) already created for', paymentIntentId);
      return;
    }

    try {
      await createAppointmentsForPayment({
        items,
        userId,
        customerName, customerEmail, customerPhone,
        paymentIntentId,
        paymentMethod: 'online',
      });
    } catch (err) {
      console.error('❌ Webhook: failed to create appointments', err);
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
const _instance = new PaymentsController();
module.exports = _instance;
module.exports.createAppointmentsForPayment = createAppointmentsForPayment;
module.exports.normalizeCartItems = normalizeCartItems;
module.exports.encodeCartIntoMetadata = encodeCartIntoMetadata;
module.exports.decodeCartFromMetadata = decodeCartFromMetadata;