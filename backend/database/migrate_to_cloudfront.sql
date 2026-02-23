-- Migrate image URLs from S3 to CloudFront
-- Run this in Supabase SQL Editor after CloudFront is set up
--
-- 1. Get your CloudFront domain: terraform output cloudfront_url
-- 2. Find-replace https://d1vkudmp7ebh7p.cloudfront.net below (e.g. https://d1234abcd.cloudfront.net)
-- 3. Run this script in Supabase SQL Editor

-- ========== REPLACE THIS WITH YOUR CLOUDFRONT URL (no trailing slash) ==========
-- Example: https://d1234abcd.cloudfront.net

-- service_categories
UPDATE service_categories
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE service_categories
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- services
UPDATE services
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE services
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- courses
UPDATE courses
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE courses
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- experts
UPDATE experts
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE experts
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- offers
UPDATE offers
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE offers
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- gallery
UPDATE gallery
SET image_url = REPLACE(image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-saad%';

UPDATE gallery
SET image_url = REPLACE(image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE image_url LIKE '%salon-app-assets-queensmarry-2026%';

-- users
UPDATE users
SET profile_image_url = REPLACE(profile_image_url, 'https://salon-app-assets-saad.s3.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE profile_image_url LIKE '%salon-app-assets-saad%';

UPDATE users
SET profile_image_url = REPLACE(profile_image_url, 'https://salon-app-assets-queensmarry-2026.s3.us-east-1.amazonaws.com', 'https://d1vkudmp7ebh7p.cloudfront.net')
WHERE profile_image_url LIKE '%salon-app-assets-queensmarry-2026%';
