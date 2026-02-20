-- Add apply_to column to offers for flexible targeting
-- Values: 'all' (both services & courses), 'all_services', 'all_courses', 'service', 'course'
ALTER TABLE offers
ADD COLUMN IF NOT EXISTS apply_to VARCHAR(20) DEFAULT 'all';

-- Backfill: derive apply_to from existing service_id/course_id
UPDATE offers SET apply_to = 'service' WHERE service_id IS NOT NULL AND (apply_to IS NULL OR apply_to = 'all');
UPDATE offers SET apply_to = 'course' WHERE course_id IS NOT NULL AND service_id IS NULL AND (apply_to IS NULL OR apply_to = 'all');
UPDATE offers SET apply_to = 'all' WHERE service_id IS NULL AND course_id IS NULL AND (apply_to IS NULL OR apply_to = '');
