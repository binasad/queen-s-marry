-- Add customer details and offer_id to course_applications
-- Run this in Supabase SQL Editor if course enrollment details are not showing in admin

ALTER TABLE course_applications
ADD COLUMN IF NOT EXISTS offer_id UUID REFERENCES offers(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_course_applications_offer ON course_applications(offer_id);
