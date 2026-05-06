const crypto = require('crypto');
const { query } = require('../../config/db');
const emailService = require('../auth/auth.service.email');

const JAZZCASH_MERCHANT_ID = process.env.JAZZCASH_MERCHANT_ID;
const JAZZCASH_PASSWORD = process.env.JAZZCASH_PASSWORD;
const JAZZCASH_INTEGRITY_SALT = process.env.JAZZCASH_INTEGRITY_SALT;
const JAZZCASH_ENDPOINT = process.env.JAZZCASH_ENDPOINT || 'https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/';
const JAZZCASH_RETURN_URL = process.env.JAZZCASH_RETURN_URL;

function generateHash(params, salt) {
  const sortedKeys = Object.keys(params).sort();
  const hashString = salt + '&' + sortedKeys.map(k => params[k]).join('&');
  return crypto.createHmac('sha256', salt).update(hashString).digest('hex');
}

function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${y}${m}${d}${h}${min}${s}`;
}

function formatExpiryDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  const s = String(date.getSeconds()).padStart(2, '0');
  return `${y}${m}${d}${h}${min}${s}`;
}

class JazzCashController {
  initiatePayment = async (req, res) => {
    try {
      const {
        amount,
        serviceId,
        appointmentDate,
        appointmentTime,
        customerName,
        customerEmail,
        customerPhone,
        offerId,
      } = req.body;

      if (!JAZZCASH_MERCHANT_ID || !JAZZCASH_PASSWORD || !JAZZCASH_INTEGRITY_SALT) {
        return res.status(500).json({ success: false, message: 'JazzCash not configured' });
      }

      const now = new Date();
      const txnDateTime = formatDate(now);
      const expiry = new Date(now.getTime() + 60 * 60 * 1000);
      const txnExpiryDateTime = formatExpiryDate(expiry);
      const txnRefNo = 'T' + txnDateTime + Math.random().toString(36).substring(2, 8).toUpperCase();

      const metadata = JSON.stringify({
        userId: req.user.id,
        serviceId,
        appointmentDate,
        appointmentTime,
        customerName,
        customerEmail,
        customerPhone,
        offerId: offerId || '',
      });

      const returnUrl = JAZZCASH_RETURN_URL || `${process.env.BACKEND_URL}/api/${process.env.API_VERSION || 'v1'}/payments/jazzcash/return`;

      const params = {
        pp_Amount: String(Math.round(amount)),
        pp_BillReference: txnRefNo,
        pp_Description: `Salon Appointment - ${customerName}`,
        pp_Language: 'EN',
        pp_MerchantID: JAZZCASH_MERCHANT_ID,
        pp_Password: JAZZCASH_PASSWORD,
        pp_ReturnURL: returnUrl,
        pp_TxnCurrency: 'PKR',
        pp_TxnDateTime: txnDateTime,
        pp_TxnExpiryDateTime: txnExpiryDateTime,
        pp_TxnRefNo: txnRefNo,
        pp_TxnType: 'MWALLET',
        pp_Version: '1.1',
        ppmpf_1: metadata,
      };

      const hash = generateHash(params, JAZZCASH_INTEGRITY_SALT);

      await query(
        `INSERT INTO jazzcash_transactions (txn_ref_no, user_id, amount, metadata, status, created_at)
         VALUES ($1, $2, $3, $4, 'pending', NOW())`,
        [txnRefNo, req.user.id, amount, metadata]
      );

      res.status(200).json({
        success: true,
        paymentUrl: JAZZCASH_ENDPOINT,
        formData: {
          ...params,
          pp_SecureHash: hash,
        },
        txnRefNo,
      });
    } catch (error) {
      console.error('❌ JazzCash initiate error:', error.message);
      res.status(500).json({ success: false, message: error.message });
    }
  };

  handleReturn = async (req, res) => {
    try {
      const data = req.body;
      console.log('📥 JazzCash return:', JSON.stringify(data));

      const responseCode = data.pp_ResponseCode;
      const txnRefNo = data.pp_TxnRefNo;
      const receivedHash = data.pp_SecureHash;

      const hashParams = { ...data };
      delete hashParams.pp_SecureHash;
      Object.keys(hashParams).forEach(k => {
        if (hashParams[k] === '' || hashParams[k] === undefined || hashParams[k] === null) {
          delete hashParams[k];
        }
      });
      const calculatedHash = generateHash(hashParams, JAZZCASH_INTEGRITY_SALT);

      if (receivedHash && calculatedHash !== receivedHash) {
        console.error('❌ JazzCash hash mismatch for', txnRefNo);
        await query(
          `UPDATE jazzcash_transactions SET status = 'hash_mismatch', response_code = $2, updated_at = NOW() WHERE txn_ref_no = $1`,
          [txnRefNo, responseCode]
        );
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment-failed?ref=${txnRefNo}&reason=integrity`);
      }

      if (responseCode === '000' || responseCode === '121') {
        await query(
          `UPDATE jazzcash_transactions SET status = 'success', response_code = $2, updated_at = NOW() WHERE txn_ref_no = $1`,
          [txnRefNo, responseCode]
        );

        await this._createAppointmentFromJazzCash(txnRefNo);

        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment-success?ref=${txnRefNo}`);
      } else {
        await query(
          `UPDATE jazzcash_transactions SET status = 'failed', response_code = $2, response_message = $3, updated_at = NOW() WHERE txn_ref_no = $1`,
          [txnRefNo, responseCode, data.pp_ResponseMessage || '']
        );
        return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment-failed?ref=${txnRefNo}&code=${responseCode}`);
      }
    } catch (error) {
      console.error('❌ JazzCash return error:', error.message);
      res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment-failed?reason=error`);
    }
  };

  handleServerNotification = async (req, res) => {
    try {
      const data = req.body;
      console.log('📥 JazzCash server notification:', JSON.stringify(data));

      const responseCode = data.pp_ResponseCode;
      const txnRefNo = data.pp_TxnRefNo;

      if (responseCode === '000' || responseCode === '121') {
        await query(
          `UPDATE jazzcash_transactions SET status = 'success', response_code = $2, updated_at = NOW() WHERE txn_ref_no = $1`,
          [txnRefNo, responseCode]
        );
        await this._createAppointmentFromJazzCash(txnRefNo);
      } else {
        await query(
          `UPDATE jazzcash_transactions SET status = 'failed', response_code = $2, response_message = $3, updated_at = NOW() WHERE txn_ref_no = $1`,
          [txnRefNo, responseCode, data.pp_ResponseMessage || '']
        );
      }

      res.status(200).send('OK');
    } catch (error) {
      console.error('❌ JazzCash notification error:', error.message);
      res.status(500).send('Error');
    }
  };

  getTransactionStatus = async (req, res) => {
    try {
      const { txnRefNo } = req.params;
      const result = await query(
        'SELECT txn_ref_no, status, response_code, amount, created_at FROM jazzcash_transactions WHERE txn_ref_no = $1 AND user_id = $2',
        [txnRefNo, req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Transaction not found' });
      }

      res.json({ success: true, transaction: result.rows[0] });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  };

  async _createAppointmentFromJazzCash(txnRefNo) {
    const txnResult = await query(
      'SELECT * FROM jazzcash_transactions WHERE txn_ref_no = $1',
      [txnRefNo]
    );

    if (txnResult.rows.length === 0) return;
    const txn = txnResult.rows[0];

    const existing = await query(
      'SELECT id FROM appointments WHERE payment_intent_id = $1',
      [txnRefNo]
    );
    if (existing.rows.length > 0) {
      console.log('✅ JazzCash: appointment already created for', txnRefNo);
      return;
    }

    let metadata;
    try {
      metadata = typeof txn.metadata === 'string' ? JSON.parse(txn.metadata) : txn.metadata;
    } catch {
      console.error('❌ JazzCash: invalid metadata for', txnRefNo);
      return;
    }

    const { userId, serviceId, appointmentDate, appointmentTime, customerName, customerEmail, customerPhone, offerId } = metadata;

    if (!userId || !serviceId || !appointmentDate || !appointmentTime) {
      console.error('❌ JazzCash: missing required metadata', metadata);
      return;
    }

    const serviceResult = await query(
      'SELECT id, name, price FROM services WHERE id = $1 AND is_active = TRUE',
      [serviceId]
    );
    if (serviceResult.rows.length === 0) return;

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
        if (applyTo !== 'all_courses' && applyTo !== 'course') {
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
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed', 'paid', 'jazzcash', $8, '', CURRENT_TIMESTAMP, $9, $10)
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
        txnRefNo,
        appliedOfferId,
      ]
    );

    const appointment = result.rows[0];
    console.log('✅ JazzCash: created appointment', appointment.id, 'for txn', txnRefNo);

    if (customerEmail && String(customerEmail).trim()) {
      emailService.sendAppointmentConfirmation(customerEmail, {
        customerName: customerName || 'Customer',
        serviceName: service.name,
        date: appointmentDate,
        time: appointmentTime,
        price: totalPrice,
      }).catch(err => console.error('❌ JazzCash: Email failed:', err.message));
    }

    if (global.io) {
      global.io.to('admin').emit('appointment-created', { appointment });
      global.io.emit('appointments-updated', { type: 'created', appointment });
    }

    const pushService = require('../../services/pushNotificationService');
    pushService.sendToUser(userId, {
      title: 'Appointment Confirmed',
      body: `Your appointment for ${service.name} on ${appointmentDate} is confirmed!`,
      data: { type: 'appointment', id: appointment.id },
    }).catch(() => {});
    pushService.sendToAdmins({
      title: 'New Booking (JazzCash)',
      body: `${customerName || 'Customer'} booked ${service.name} for ${appointmentDate} (paid via JazzCash)`,
      data: { type: 'appointment', id: appointment.id },
    }).catch(() => {});
  }
}

module.exports = new JazzCashController();
