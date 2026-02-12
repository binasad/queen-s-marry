-- Add service_id and course_id to offers table for linking offers to services/courses
-- Run this migration to enable offer -> service/course navigation in the mobile app

ALTER TABLE offers
ADD COLUMN IF NOT EXISTS service_id UUID REFERENCES services(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_offers_service_id ON offers(service_id);
CREATE INDEX IF NOT EXISTS idx_offers_course_id ON offers(course_id);
