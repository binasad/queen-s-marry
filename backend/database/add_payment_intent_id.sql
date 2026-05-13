-- Add payment_intent_id to appointments for webhook idempotency.
--
-- NOTE: this column is NOT unique. A single payment (one Stripe PaymentIntent
-- or one JazzCash txnRefNo) can produce multiple appointment rows when a cart
-- with multiple services is paid for in one transaction. Idempotency on the
-- payment side relies on the application-level check
-- `SELECT id FROM appointments WHERE payment_intent_id = $1`.
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255);

-- Drop any pre-existing unique constraint left over from older deployments.
ALTER TABLE appointments
DROP CONSTRAINT IF EXISTS appointments_payment_intent_id_key;

CREATE INDEX IF NOT EXISTS idx_appointments_payment_intent ON appointments(payment_intent_id)
WHERE payment_intent_id IS NOT NULL;
