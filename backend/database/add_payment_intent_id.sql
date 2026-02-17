-- Add payment_intent_id to appointments for webhook idempotency
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) UNIQUE;

CREATE INDEX IF NOT EXISTS idx_appointments_payment_intent ON appointments(payment_intent_id)
WHERE payment_intent_id IS NOT NULL;
