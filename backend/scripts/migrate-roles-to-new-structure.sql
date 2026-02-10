-- Migration script to update roles to new structure
-- This will:
-- 1. Migrate permissions from old roles to new capitalized roles
-- 2. Update user role assignments
-- 3. Create missing roles (Expert, Manager, Sales, User if needed)
-- 4. Delete old duplicate roles

BEGIN;

-- Step 1: Create missing roles if they don't exist
INSERT INTO roles (name, is_system_role) VALUES 
    ('Expert', FALSE),
    ('Manager', FALSE),
    ('Sales', FALSE),
    ('User', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Step 2: Migrate permissions from lowercase 'admin' to 'Admin'
-- (Only if lowercase admin exists and has permissions)
DO $$
DECLARE
    old_admin_id UUID;
    new_admin_id UUID;
BEGIN
    -- Get IDs
    SELECT id INTO old_admin_id FROM roles WHERE name = 'admin' LIMIT 1;
    SELECT id INTO new_admin_id FROM roles WHERE name = 'Admin' LIMIT 1;
    
    IF old_admin_id IS NOT NULL AND new_admin_id IS NOT NULL THEN
        -- Copy permissions from old admin to new Admin
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT new_admin_id, permission_id
        FROM role_permissions
        WHERE role_id = old_admin_id
        ON CONFLICT (role_id, permission_id) DO NOTHING;
        
        RAISE NOTICE 'Migrated permissions from admin to Admin';
    END IF;
END $$;

-- Step 3: Migrate permissions from lowercase 'expert' to 'Expert'
DO $$
DECLARE
    old_expert_id UUID;
    new_expert_id UUID;
BEGIN
    SELECT id INTO old_expert_id FROM roles WHERE name = 'expert' LIMIT 1;
    SELECT id INTO new_expert_id FROM roles WHERE name = 'Expert' LIMIT 1;
    
    IF old_expert_id IS NOT NULL AND new_expert_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT new_expert_id, permission_id
        FROM role_permissions
        WHERE role_id = old_expert_id
        ON CONFLICT (role_id, permission_id) DO NOTHING;
        
        RAISE NOTICE 'Migrated permissions from expert to Expert';
    END IF;
END $$;

-- Step 4: Migrate permissions from lowercase 'owner' to 'Owner' (if Owner doesn't exist)
DO $$
DECLARE
    old_owner_id UUID;
    new_owner_id UUID;
BEGIN
    SELECT id INTO old_owner_id FROM roles WHERE name = 'owner' LIMIT 1;
    SELECT id INTO new_owner_id FROM roles WHERE name = 'Owner' LIMIT 1;
    
    -- Create Owner if it doesn't exist
    IF new_owner_id IS NULL THEN
        INSERT INTO roles (name, is_system_role) VALUES ('Owner', TRUE) RETURNING id INTO new_owner_id;
    END IF;
    
    IF old_owner_id IS NOT NULL AND new_owner_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT new_owner_id, permission_id
        FROM role_permissions
        WHERE role_id = old_owner_id
        ON CONFLICT (role_id, permission_id) DO NOTHING;
        
        RAISE NOTICE 'Migrated permissions from owner to Owner';
    END IF;
END $$;

-- Step 5: Update user role assignments from old roles to new roles
UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'Admin' LIMIT 1)
WHERE role_id = (SELECT id FROM roles WHERE name = 'admin' LIMIT 1);

UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'Expert' LIMIT 1)
WHERE role_id = (SELECT id FROM roles WHERE name = 'expert' LIMIT 1);

UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'Owner' LIMIT 1)
WHERE role_id = (SELECT id FROM roles WHERE name = 'owner' LIMIT 1);

-- Step 6: Delete old duplicate roles (only if no users are assigned to them)
-- First, set any remaining users with old roles to NULL or a default role
UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'User' LIMIT 1)
WHERE role_id IN (
    SELECT id FROM roles WHERE LOWER(name) IN ('admin', 'expert', 'owner') 
    AND name != INITCAP(name)
);

-- Delete old lowercase roles and their permission mappings
DELETE FROM role_permissions 
WHERE role_id IN (
    SELECT id FROM roles 
    WHERE LOWER(name) IN ('admin', 'expert', 'owner') 
    AND name != INITCAP(name)
);

DELETE FROM roles 
WHERE LOWER(name) IN ('admin', 'expert', 'owner') 
AND name != INITCAP(name);

-- Step 7: Ensure Admin has all permissions (if it's a system role)
DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE name = 'Admin' LIMIT 1;
    
    IF admin_role_id IS NOT NULL THEN
        -- Give Admin all permissions
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT admin_role_id, id FROM permissions
        ON CONFLICT (role_id, permission_id) DO NOTHING;
    END IF;
END $$;

-- Step 8: Ensure Owner has all permissions
DO $$
DECLARE
    owner_role_id UUID;
BEGIN
    SELECT id INTO owner_role_id FROM roles WHERE name = 'Owner' LIMIT 1;
    
    IF owner_role_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT owner_role_id, id FROM permissions
        ON CONFLICT (role_id, permission_id) DO NOTHING;
    END IF;
END $$;

-- Step 9: Verify final state
SELECT 
    'Migration Summary' as info,
    (SELECT COUNT(*) FROM roles WHERE name IN ('Admin', 'Expert', 'User', 'Manager', 'Sales')) as required_roles_count,
    (SELECT COUNT(*) FROM roles) as total_roles_count;

COMMIT;

-- Show final roles
SELECT 
    id,
    name,
    is_system_role,
    (SELECT COUNT(*) FROM role_permissions WHERE role_id = r.id) as permission_count
FROM roles r
ORDER BY name;
