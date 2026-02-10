-- Migration: Add role_id to existing users table
-- Run this AFTER roles/permissions tables exist

BEGIN;

-- 1. Add role_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'role_id'
    ) THEN
        ALTER TABLE users ADD COLUMN role_id UUID REFERENCES roles(id);
    END IF;
END $$;

-- 2. Migrate existing role strings to role_id (if old 'role' column exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'role'
    ) THEN
        -- Map old role strings to new role_id
        UPDATE users u
        SET role_id = r.id
        FROM roles r
        WHERE LOWER(u.role) = LOWER(r.name);
        
        -- Set default 'User' role for any unmapped users
        UPDATE users
        SET role_id = (SELECT id FROM roles WHERE name = 'User')
        WHERE role_id IS NULL;
        
        -- Drop old role column
        ALTER TABLE users DROP COLUMN role;
    END IF;
END $$;

-- 3. Create index if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_users_role_id'
    ) THEN
        CREATE INDEX idx_users_role_id ON users(role_id);
    END IF;
END $$;

COMMIT;

-- Verify migration
SELECT 
    u.id, 
    u.name, 
    u.email, 
    r.name as role_name,
    COUNT(p.slug) as permission_count
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
LEFT JOIN permissions p ON p.id = rp.permission_id
GROUP BY u.id, u.name, u.email, r.name
ORDER BY u.created_at DESC
LIMIT 10;
