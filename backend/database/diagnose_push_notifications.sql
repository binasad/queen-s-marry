-- Run this in your SQL editor to diagnose push notification setup
-- Replace with your actual customer email or user ID to test

-- 1. Check which users have FCM tokens saved
SELECT 
  u.id,
  u.email,
  u.name,
  r.name AS role_name,
  CASE WHEN u.fcm_token IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_token,
  LENGTH(u.fcm_token) AS token_length
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
WHERE r.name IN ('Customer', 'User', 'Admin', 'Owner')
ORDER BY has_token DESC, r.name;

-- 2. Count users by role and token status
SELECT 
  r.name AS role_name,
  COUNT(*) FILTER (WHERE u.fcm_token IS NOT NULL) AS with_token,
  COUNT(*) FILTER (WHERE u.fcm_token IS NULL) AS without_token
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE r.name IN ('Customer', 'User')
GROUP BY r.name;

-- 3. Get a specific customer's user ID (for test-push API)
-- Replace 'customer@example.com' with the actual customer email
SELECT id, email, name, fcm_token IS NOT NULL AS has_token
FROM users 
WHERE email = 'customer@example.com';
