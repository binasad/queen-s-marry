-- Add offer_id to appointments so we can track when a booking was made with an offer
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS offer_id UUID REFERENCES offers(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_appointments_offer ON appointments(offer_id);
