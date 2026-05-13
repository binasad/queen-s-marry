-- Make per-cart-line appointments unique within a single payment intent.
--
-- The old UNIQUE on `payment_intent_id` was dropped earlier so multi-item
-- carts can share one payment. We replace it with a composite UNIQUE so a
-- racing webhook + /payments/confirm-appointment pair can't insert the same
-- cart line twice. Combined with `INSERT ... ON CONFLICT DO NOTHING`, only
-- one of the racing inserts wins per (payment, service, date, time) tuple.
--
-- The partial WHERE clause keeps legacy NULL-payment_intent_id rows
-- (cash/in-store bookings) out of the constraint.

ALTER TABLE appointments
  DROP CONSTRAINT IF EXISTS appointments_payment_line_unique;

CREATE UNIQUE INDEX IF NOT EXISTS appointments_payment_line_unique
  ON appointments(payment_intent_id, service_id, appointment_date, appointment_time)
  WHERE payment_intent_id IS NOT NULL;
