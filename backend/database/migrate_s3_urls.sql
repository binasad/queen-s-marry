-- Migrate S3 URLs from old bucket to new bucket
-- Run this in Supabase SQL Editor after uploading assets to the new bucket
-- Old: https://salon-app-assets-saad.s3.amazonaws.com
-- New: https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com

UPDATE service_categories
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE services
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE courses
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE experts
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE offers
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE gallery
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE users
SET profile_image_url = REPLACE(profile_image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com')
WHERE profile_image_url LIKE '%salon-app-assets-saad%';
