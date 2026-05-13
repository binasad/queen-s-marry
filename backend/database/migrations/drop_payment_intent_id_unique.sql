-- Drop the UNIQUE constraint on appointments.payment_intent_id so that a
-- single payment (Stripe PaymentIntent or JazzCash txnRefNo) can be linked to
-- multiple appointment rows — one per cart item.
--
-- The constraint name follows the convention `<table>_<column>_key` for
-- Postgres-generated unique constraints from `... UNIQUE` column defs. If a
-- previous deployment used a different name (e.g. set manually), drop that one
-- via psql first.

ALTER TABLE appointments
  DROP CONSTRAINT IF EXISTS appointments_payment_intent_id_key;

-- Make sure a non-unique index remains for fast idempotency lookups
-- (`SELECT id FROM appointments WHERE payment_intent_id = $1`).
CREATE INDEX IF NOT EXISTS idx_appointments_payment_intent
  ON appointments(payment_intent_id)
  WHERE payment_intent_id IS NOT NULL;
