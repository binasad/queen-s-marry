-- Check if any tokens are stored in the database
-- This will show all users with setup tokens

SELECT 
    email,
    name,
    reset_password_token,
    reset_password_expires,
    CASE 
        WHEN reset_password_expires > CURRENT_TIMESTAMP THEN 'Valid'
        WHEN reset_password_expires IS NOT NULL THEN 'Expired'
        ELSE 'No Token'
    END AS token_status
FROM users 
WHERE reset_password_token IS NOT NULL
ORDER BY reset_password_expires DESC;

-- Count total tokens
SELECT 
    COUNT(*) as total_tokens,
    COUNT(*) FILTER (WHERE reset_password_expires > CURRENT_TIMESTAMP) as valid_tokens,
    COUNT(*) FILTER (WHERE reset_password_expires <= CURRENT_TIMESTAMP) as expired_tokens
FROM users 
WHERE reset_password_token IS NOT NULL;
