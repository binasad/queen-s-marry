const crypto = require('crypto');
const { query } = require('../../config/db');
const emailService = require('../auth/auth.service.email');

const JAZZCASH_MERCHANT_ID = process.env.JAZZCASH_MERCHANT_ID || 'MC735135';
const JAZZCASH_PASSWORD = process.env.JAZZCASH_PASSWORD || 'y6yhfw7130';
const JAZZCASH_INTEGRITY_SALT = process.env.JAZZCASH_INTEGRITY_SALT || '';
const JAZZCASH_HPC_BASE = process.env.JAZZCASH_HPC_BASE || 'https://sandbox.jazzcash.com.pk';
const JAZZCASH_POST_URL = process.env.JAZZCASH_POST_URL
  || `${JAZZCASH_HPC_BASE}/CustomerPortal/transactionmanagement/merchantform/`;
const JAZZCASH_RETURN_URL = process.env.JAZZCASH_RETURN_URL;

function generateHash(params, salt) {
  const sortedKeys = Object.keys(params)
    .filter(k => k !== 'pp_SecureHash' && params[k] !== '' && params[k] != null)
    .sort();
  const hashString = salt + '&' + sortedKeys.map(k => params[k]).join('&');
  const hash = crypto.createHmac('sha256', salt).update(hashString).digest('hex').toUpperCase();
  if (process.env.JAZZCASH_DEBUG === '1') {
    console.log('🔐 JazzCash hash sortedKeys:', sortedKeys);
    console.log('🔐 JazzCash hash dataString:', hashString);
    console.log('🔐 JazzCash hash result:', hash);
  }
  return hash;
}

function pad(n) { return String(n).padStart(2, '0'); }
function formatDate(date) {
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function buildCardCheckoutHtml({ payload, hpcBase, returnUrl }) {
  const cardFieldOrder = [
    'pp_Version', 'pp_MerchantID', 'pp_SubMerchantID', 'pp_Language', 'pp_TxnType',
    'pp_Password', 'pp_TxnRefNo', 'pp_Amount', 'pp_DiscountedAmount', 'pp_DiscountBank',
    'pp_TxnCurrency', 'pp_TxnDateTime', 'pp_TxnExpiryDateTime', 'pp_BillReference',
    'pp_Description', 'pp_ReturnURL', 'ppmpf_1', 'ppmpf_2', 'ppmpf_3', 'ppmpf_4',
    'ppmpf_5', 'pp_SecureHash', 'pp_Frequency', 'C3DSecureID', 'GateWayCode',
    'SummaryStatus', 'ResponseCode', 'ResponseMessage', 'pp_RetreivalReferenceNo',
    'pp_InstrToken',
  ];
  const initialFields = cardFieldOrder
    .map(k => `      <input type="hidden" id="${k}" name="${k}" value="${escapeHtml(payload[k])}" />`)
    .join('\n');

  const payloadJs = JSON.stringify(payload);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>JazzCash Card Payment</title>
  <style>
    body { font-family: Arial, sans-serif; margin:0; background:#f8f9fa; min-height:100vh; }
    .wrap { max-width:560px; margin:0 auto; padding:20px; }
    h2 { color:#c4151c; }
    #JazzCashErrorDiv { color:red; padding:8px 0; }
    #JazzCashSuccessDiv { color:green; padding:8px 0; }
  </style>
  <script src="https://code.jquery.com/jquery-2.1.4.js"></script>
  <script src="${hpcBase}/HostedPay/Scripts/PayChk3DS.js"></script>
</head>
<body>
  <div class="wrap">
    <h2>Pay with Card</h2>
    <form id="onlineform" action="${escapeHtml(returnUrl)}" method="POST">
      <div id="JazzCashFields">
        <div id="JazzCashErrorDiv" style="display:none;"></div>
        <div id="JazzCashSuccessDiv" style="display:none;"></div>
      </div>
${initialFields}
      <noscript><button type="submit">Continue</button></noscript>
    </form>
  </div>
  <script>
    var pp_payload = ${payloadJs};
    $(document).ready(function () {
      try {
        populateJazzCashFields(pp_payload);
      } catch (e) {
        var err = document.getElementById('JazzCashErrorDiv');
        err.style.display = 'block';
        err.textContent = 'Failed to initialize JazzCash card form: ' + e.message;
      }
    });
    window.addEventListener('message', function (evt) {
      try {
        var obj = typeof evt.data === 'string' ? JSON.parse(evt.data) : evt.data;
        if (!obj || typeof obj !== 'object') return;
        Object.keys(obj).forEach(function (k) {
          var el = document.getElementById(k);
          if (el) el.value = obj[k] == null ? '' : obj[k];
        });
        document.getElementById('onlineform').submit();
      } catch (e) {
        var err = document.getElementById('JazzCashErrorDiv');
        err.style.display = 'block';
        err.textContent = 'Failed to process card response: ' + e.message;
      }
    }, false);
  </script>
</body>
</html>`;
}

function buildHostedCheckoutHtml({ payload, postUrl }) {
  const fieldOrder = [
    'pp_Version', 'pp_MerchantID', 'pp_Language', 'pp_TxnType', 'pp_SubMerchantID',
    'pp_Password', 'pp_BankID', 'pp_ProductID', 'pp_TxnRefNo', 'pp_Amount',
    'pp_TxnCurrency', 'pp_TxnDateTime', 'pp_TxnExpiryDateTime', 'pp_BillReference',
    'pp_Description', 'pp_ReturnURL', 'ppmpf_1', 'ppmpf_2', 'ppmpf_3', 'ppmpf_4',
    'ppmpf_5', 'pp_SecureHash', 'pp_MobileNumber', 'pp_CNIC',
  ];
  const inputs = fieldOrder
    .map(k => `      <input type="hidden" name="${k}" value="${escapeHtml(payload[k])}" />`)
    .join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redirecting to JazzCash</title>
  <style>
    body { font-family: Arial, sans-serif; display:flex; min-height:100vh; align-items:center; justify-content:center; margin:0; background:#f8f9fa; }
    .card { text-align:center; padding:32px; background:#fff; border-radius:16px; box-shadow:0 10px 30px rgba(0,0,0,.08); }
    .spinner { width:42px; height:42px; margin:0 auto 16px; border:4px solid #eee; border-top-color:#c4151c; border-radius:50%; animation:spin 1s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="spinner"></div>
    <p>Redirecting to JazzCash...</p>
    <form id="onlineform" action="${escapeHtml(postUrl)}" method="POST">
${inputs}
      <noscript><button type="submit">Continue to JazzCash</button></noscript>
    </form>
  </div>
  <script>
    document.getElementById('onlineform').submit();
  </script>
</body>
</html>`;
}

function buildResultHtml({ success, responseCode, responseMessage, rrn, txnRefNo, frontendUrl }) {
  const color = success ? '#16a34a' : '#dc2626';
  const title = success ? 'Payment Successful' : 'Payment Failed';
  const icon = success ? '&#10003;' : '&#10005;';
  const redirect = success
    ? `${frontendUrl}/payment-success?ref=${encodeURIComponent(txnRefNo || '')}`
    : `${frontendUrl}/payment-failed?ref=${encodeURIComponent(txnRefNo || '')}&code=${encodeURIComponent(responseCode || '')}`;
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <meta http-equiv="refresh" content="4;url=${redirect}">
  <style>
    body { font-family: Arial, sans-serif; display:flex; min-height:100vh; align-items:center; justify-content:center; margin:0; background:#f8f9fa; }
    .card { text-align:center; padding:32px 40px; background:#fff; border-radius:16px; box-shadow:0 10px 30px rgba(0,0,0,.08); max-width:480px; }
    .icon { font-size:48px; color:${color}; margin-bottom:8px; }
    h1 { color:${color}; margin:0 0 16px; }
    .row { font-size:14px; color:#333; margin:6px 0; }
    .label { color:#666; }
    a { color:#c4151c; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${icon}</div>
    <h1>${title}</h1>
    <div class="row"><span class="label">Response Message:</span> ${responseMessage || ''}</div>
    <div class="row"><span class="label">Response Code:</span> ${responseCode || ''}</div>
    <div class="row"><span class="label">RRN:</span> ${rrn || ''}</div>
    <div class="row"><span class="label">Txn Ref:</span> ${txnRefNo || ''}</div>
    <p style="margin-top:24px;font-size:13px;color:#666;">Redirecting in 4 seconds... <a href="${redirect}">Continue now</a></p>
  </div>
</body>
</html>`;
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
        returnUrl: returnUrlOverride,
        paymentMethod,
      } = req.body;
      const method = String(paymentMethod || 'wallet').toLowerCase() === 'card' ? 'card' : 'wallet';

      if (!JAZZCASH_MERCHANT_ID || !JAZZCASH_PASSWORD) {
        return res.status(500).json({ success: false, message: 'JazzCash not configured' });
      }

      const now = new Date();
      const txnDateTime = formatDate(now);
      const txnExpiryDateTime = formatDate(new Date(now.getTime() + 8 * 60 * 60 * 1000));
      const txnRefNo = 'T' + txnDateTime;

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

      const defaultReturn = JAZZCASH_RETURN_URL
        || (process.env.BACKEND_URL
          ? `${process.env.BACKEND_URL}/api/${process.env.API_VERSION || 'v1'}/payments/jazzcash/return`
          : 'https://api.queensmarrybeautysaloon.com/api/v1/payments/jazzcash/return');
      const returnUrl = (returnUrlOverride && String(returnUrlOverride).trim()) || defaultReturn;

      // Amount expected in paisas (e.g. 1 PKR -> 100). Caller already converts.
      const formattedAmount = String(Math.round(parseFloat(amount)));

      if (!JAZZCASH_INTEGRITY_SALT) {
        return res.status(500).json({
          success: false,
          message: 'JAZZCASH_INTEGRITY_SALT env var is required to sign the request',
        });
      }

      let payload;
      let html;
      if (method === 'card') {
        const cardExpiry = formatDate(new Date(now.getTime() + 3 * 60 * 60 * 1000));
        payload = {
          pp_Version: '1.1',
          pp_MerchantID: JAZZCASH_MERCHANT_ID,
          pp_TxnType: 'MPAY',
          pp_Password: JAZZCASH_PASSWORD,
          pp_TxnRefNo: txnRefNo,
          pp_DiscountedAmount: '',
          pp_DiscountBank: '',
          pp_Amount: formattedAmount,
          pp_TxnCurrency: 'PKR',
          pp_TxnDateTime: txnDateTime,
          pp_TxnExpiryDateTime: cardExpiry,
          pp_BillReference: 'billRef',
          pp_Description: `Salon Appointment - ${customerName || 'Customer'}`,
          pp_ReturnURL: returnUrl,
          ppmpf_1: txnRefNo,
          ppmpf_2: '',
          ppmpf_3: '',
          ppmpf_4: '',
          ppmpf_5: '',
        };
        payload.pp_SecureHash = generateHash(payload, JAZZCASH_INTEGRITY_SALT);
      } else {
        payload = {
          pp_Version: '1.1',
          pp_MerchantID: JAZZCASH_MERCHANT_ID,
          pp_Language: 'EN',
          pp_TxnType: 'MWALLET',
          pp_SubMerchantID: '',
          pp_Password: JAZZCASH_PASSWORD,
          pp_BankID: '',
          pp_ProductID: '',
          pp_TxnRefNo: txnRefNo,
          pp_Amount: formattedAmount,
          pp_TxnCurrency: 'PKR',
          pp_TxnDateTime: txnDateTime,
          pp_TxnExpiryDateTime: txnExpiryDateTime,
          pp_BillReference: 'billRef',
          pp_Description: `Salon Appointment - ${customerName || 'Customer'}`,
          pp_ReturnURL: returnUrl,
          ppmpf_1: txnRefNo,
          ppmpf_2: '',
          ppmpf_3: '',
          ppmpf_4: '',
          ppmpf_5: '',
          pp_MobileNumber: customerPhone || '',
          pp_CNIC: '',
        };
        payload.pp_SecureHash = generateHash(payload, JAZZCASH_INTEGRITY_SALT);
      }

      await query(
        `INSERT INTO jazzcash_transactions (txn_ref_no, user_id, amount, metadata, status, created_at)
         VALUES ($1, $2, $3, $4, 'pending', NOW())`,
        [txnRefNo, req.user.id, amount, metadata]
      );

      if (method === 'card') {
        html = buildCardCheckoutHtml({
          payload,
          hpcBase: JAZZCASH_HPC_BASE,
          returnUrl,
        });
      } else {
        html = buildHostedCheckoutHtml({
          payload,
          postUrl: JAZZCASH_POST_URL,
        });
      }

      const wantsHtml = req.accepts(['html', 'json']) === 'html' || String(req.query.format || '').toLowerCase() === 'html';
      if (wantsHtml) {
        res.set('Content-Type', 'text/html; charset=utf-8');
        return res.status(200).send(html);
      }

      res.status(200).json({
        success: true,
        txnRefNo,
        paymentMethod: method,
        checkoutHtml: html,
        hpcUrl: method === 'card' ? returnUrl : JAZZCASH_POST_URL,
        payload,
      });
    } catch (error) {
      console.error('❌ JazzCash initiate error:', error.message);
      res.status(500).json({ success: false, message: error.message });
    }
  };

  handleReturn = async (req, res) => {
    try {
      const data = { ...(req.body || {}), ...(req.query || {}) };
      console.log('📥 JazzCash return:', JSON.stringify(data));

      const responseCode = data.pp_ResponseCode || data.ResponseCode;
      const responseMessage = data.pp_ResponseMessage || data.ResponseMessage || '';
      const rrn = data.pp_RetreivalReferenceNo || data.pp_RetrievalReferenceNo || '';
      const txnRefNo = data.pp_TxnRefNo || data.ppmpf_1 || '';
      const instrToken = data.pp_InstrToken || '';
      if (instrToken) console.log('💳 JazzCash card instr token for', txnRefNo, ':', instrToken);

      const success = responseCode === '000' || responseCode === '121';
      const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';

      if (txnRefNo) {
        if (success) {
          await query(
            `UPDATE jazzcash_transactions SET status='success', response_code=$2, response_message=$3, updated_at=NOW() WHERE txn_ref_no=$1`,
            [txnRefNo, responseCode, responseMessage]
          );
          await this._createAppointmentFromJazzCash(txnRefNo);
        } else {
          await query(
            `UPDATE jazzcash_transactions SET status='failed', response_code=$2, response_message=$3, updated_at=NOW() WHERE txn_ref_no=$1`,
            [txnRefNo, responseCode || 'unknown', responseMessage]
          );
        }
      }

      res.set('Content-Type', 'text/html; charset=utf-8');
      return res.status(200).send(buildResultHtml({
        success,
        responseCode,
        responseMessage,
        rrn,
        txnRefNo,
        frontendUrl,
      }));
    } catch (error) {
      console.error('❌ JazzCash return error:', error.message);
      const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
      res.set('Content-Type', 'text/html; charset=utf-8');
      res.status(200).send(buildResultHtml({
        success: false,
        responseCode: 'ERR',
        responseMessage: error.message,
        rrn: '',
        txnRefNo: '',
        frontendUrl,
      }));
    }
  };

  handleServerNotification = async (req, res) => {
    try {
      const data = req.body || {};
      console.log('📥 JazzCash server notification:', JSON.stringify(data));

      const responseCode = data.pp_ResponseCode;
      const txnRefNo = data.pp_TxnRefNo;

      if (responseCode === '000' || responseCode === '121') {
        await query(
          `UPDATE jazzcash_transactions SET status='success', response_code=$2, updated_at=NOW() WHERE txn_ref_no=$1`,
          [txnRefNo, responseCode]
        );
        await this._createAppointmentFromJazzCash(txnRefNo);
      } else {
        await query(
          `UPDATE jazzcash_transactions SET status='failed', response_code=$2, response_message=$3, updated_at=NOW() WHERE txn_ref_no=$1`,
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

    const { userId, serviceId, appointmentDate, appointmentTime, customerName, customerEmail, customerPhone, offerId } = metadata || {};
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
