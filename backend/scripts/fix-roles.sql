-- Script to fix roles: Remove duplicates and ensure required roles exist
-- WARNING: This will delete duplicate lowercase roles and migrate their permissions
-- Run this carefully and backup your database first!

BEGIN;

-- Step 1: Migrate permissions from lowercase 'admin' to 'Admin' if Admin exists
DO $$
DECLARE
    admin_lower_id UUID;
    admin_upper_id UUID;
BEGIN
    -- Get IDs
    SELECT id INTO admin_lower_id FROM roles WHERE name = 'admin' LIMIT 1;
    SELECT id INTO admin_upper_id FROM roles WHERE name = 'Admin' LIMIT 1;
    
    -- If both exist, migrate permissions from lowercase to uppercase
    IF admin_lower_id IS NOT NULL AND admin_upper_id IS NOT NULL THEN
        -- Copy permissions from lowercase admin to uppercase Admin
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT admin_upper_id, permission_id
        FROM role_permissions
        WHERE role_id = admin_lower_id
        ON CONFLICT DO NOTHING;
        
        -- Update users assigned to lowercase admin to uppercase Admin
        UPDATE users SET role_id = admin_upper_id WHERE role_id = admin_lower_id;
        
        -- Delete lowercase admin
        DELETE FROM roles WHERE id = admin_lower_id;
        
        RAISE NOTICE 'Migrated permissions from admin to Admin and deleted duplicate';
    END IF;
END $$;

-- Step 2: Create missing required roles (if they don't exist)
INSERT INTO roles (name, is_system_role) VALUES 
    ('Expert', FALSE),
    ('Manager', FALSE),
    ('Sales', FALSE)
ON CONFLICT (name) DO NOTHING;

-- Step 3: Ensure User role exists (capitalized)
INSERT INTO roles (name, is_system_role) VALUES 
    ('User', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Step 4: If lowercase 'user' exists, migrate to uppercase 'User'
DO $$
DECLARE
    user_lower_id UUID;
    user_upper_id UUID;
BEGIN
    SELECT id INTO user_lower_id FROM roles WHERE name = 'user' LIMIT 1;
    SELECT id INTO user_upper_id FROM roles WHERE name = 'User' LIMIT 1;
    
    IF user_lower_id IS NOT NULL AND user_upper_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT user_upper_id, permission_id
        FROM role_permissions
        WHERE role_id = user_lower_id
        ON CONFLICT DO NOTHING;
        
        UPDATE users SET role_id = user_upper_id WHERE role_id = user_lower_id;
        DELETE FROM roles WHERE id = user_lower_id;
        
        RAISE NOTICE 'Migrated permissions from user to User and deleted duplicate';
    END IF;
END $$;

-- Step 5: If lowercase 'expert' exists, migrate to uppercase 'Expert'
DO $$
DECLARE
    expert_lower_id UUID;
    expert_upper_id UUID;
BEGIN
    SELECT id INTO expert_lower_id FROM roles WHERE name = 'expert' LIMIT 1;
    SELECT id INTO expert_upper_id FROM roles WHERE name = 'Expert' LIMIT 1;
    
    IF expert_lower_id IS NOT NULL AND expert_upper_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT expert_upper_id, permission_id
        FROM role_permissions
        WHERE role_id = expert_lower_id
        ON CONFLICT DO NOTHING;
        
        UPDATE users SET role_id = expert_upper_id WHERE role_id = expert_lower_id;
        DELETE FROM roles WHERE id = expert_lower_id;
        
        RAISE NOTICE 'Migrated permissions from expert to Expert and deleted duplicate';
    END IF;
END $$;

-- Step 6: Delete lowercase 'owner' if uppercase 'Owner' exists (Owner is system role)
DO $$
DECLARE
    owner_lower_id UUID;
    owner_upper_id UUID;
BEGIN
    SELECT id INTO owner_lower_id FROM roles WHERE name = 'owner' LIMIT 1;
    SELECT id INTO owner_upper_id FROM roles WHERE name = 'Owner' LIMIT 1;
    
    IF owner_lower_id IS NOT NULL AND owner_upper_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT owner_upper_id, permission_id
        FROM role_permissions
        WHERE role_id = owner_lower_id
        ON CONFLICT DO NOTHING;
        
        UPDATE users SET role_id = owner_upper_id WHERE role_id = owner_lower_id;
        DELETE FROM roles WHERE id = owner_lower_id;
        
        RAISE NOTICE 'Migrated permissions from owner to Owner and deleted duplicate';
    END IF;
END $$;

-- Verify final state
SELECT 'Final roles:' as status;
SELECT id, name, is_system_role FROM roles ORDER BY name;

COMMIT;
