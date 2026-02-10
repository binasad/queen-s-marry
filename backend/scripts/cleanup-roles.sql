-- Cleanup Roles Script
-- Removes unwanted roles and keeps only: Admin, Manager, Sales, Expert
-- Creates Manager and Sales roles if they don't exist

BEGIN;

-- Step 1: First, handle users assigned to roles we're about to delete
-- Set their role_id to NULL (or you can reassign to Admin if preferred)
UPDATE users 
SET role_id = NULL 
WHERE role_id IN (
    SELECT id FROM roles 
    WHERE LOWER(name) IN ('owner', 'user') 
    AND name NOT IN ('Admin', 'Manager', 'Sales', 'Expert')
);

-- Step 2: Delete unwanted roles (this will cascade delete role_permissions)
-- Delete lowercase duplicates and unwanted roles
DELETE FROM roles 
WHERE name IN ('owner', 'user', 'admin') 
   OR (name = 'Owner' AND is_system_role = TRUE)
   OR (name = 'User' AND is_system_role = TRUE);

-- Step 3: Ensure Admin exists (keep the capitalized system role)
-- If Admin doesn't exist, create it
INSERT INTO roles (name, is_system_role) 
VALUES ('Admin', TRUE)
ON CONFLICT (name) DO UPDATE SET is_system_role = TRUE;

-- Step 4: Ensure Expert exists (keep lowercase expert or create if needed)
-- First check if Expert (capitalized) exists, if not check for expert (lowercase)
DO $$
DECLARE
    expert_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM roles WHERE name = 'Expert') INTO expert_exists;
    IF NOT expert_exists THEN
        -- Check if lowercase expert exists
        IF EXISTS(SELECT 1 FROM roles WHERE name = 'expert') THEN
            -- Rename lowercase to capitalized
            UPDATE roles SET name = 'Expert' WHERE name = 'expert';
        ELSE
            -- Create Expert role
            INSERT INTO roles (name, is_system_role) VALUES ('Expert', FALSE);
        END IF;
    END IF;
END $$;

-- Step 5: Create Manager role if it doesn't exist
INSERT INTO roles (name, is_system_role) 
VALUES ('Manager', FALSE)
ON CONFLICT (name) DO NOTHING;

-- Step 6: Create Sales role if it doesn't exist
INSERT INTO roles (name, is_system_role) 
VALUES ('Sales', FALSE)
ON CONFLICT (name) DO NOTHING;

-- Step 7: Assign permissions to Admin (if not already assigned)
-- Admin gets most permissions (similar to current setup)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE name = 'Admin'),
    id 
FROM permissions
WHERE slug IN (
    'auth.login',
    'auth.logout',
    'auth.change-password',
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'users.assign-role',
    'roles.view',
    'roles.create',
    'roles.update',
    'roles.delete',
    'services.view',
    'services.manage',
    'categories.manage',
    'appointments.view',
    'appointments.manage',
    'appointments.cancel',
    'appointments.manage_all',
    'appointments.create',
    'offers.view',
    'offers.manage',
    'courses.view',
    'courses.manage',
    'experts.view',
    'experts.manage',
    'gallery.view',
    'gallery.manage',
    'support.view',
    'support.manage',
    'dashboard.view',
    'reports.view',
    'notifications.send',
    'notifications.manage'
)
ON CONFLICT DO NOTHING;

-- Step 8: Assign permissions to Expert (if not already assigned)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE name = 'Expert'),
    id 
FROM permissions
WHERE slug IN (
    'auth.login',
    'auth.logout',
    'auth.change-password',
    'appointments.view',
    'appointments.manage',
    'appointments.cancel',
    'appointments.create',
    'users.view',
    'dashboard.view',
    'courses.view',
    'courses.manage',
    'offers.view',
    'offers.manage',
    'services.view',
    'experts.view'
)
ON CONFLICT DO NOTHING;

-- Step 9: Assign permissions to Manager
-- Manager gets most permissions except sensitive financial/system config
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE name = 'Manager'),
    id 
FROM permissions
WHERE slug IN (
    'auth.login',
    'auth.logout',
    'auth.change-password',
    'users.view',
    'users.create',
    'users.update',
    'services.view',
    'services.manage',
    'categories.manage',
    'appointments.view',
    'appointments.manage',
    'appointments.cancel',
    'appointments.manage_all',
    'appointments.create',
    'offers.view',
    'offers.manage',
    'courses.view',
    'courses.manage',
    'experts.view',
    'experts.manage',
    'gallery.view',
    'gallery.manage',
    'support.view',
    'support.manage',
    'dashboard.view',
    'reports.view',
    'notifications.send',
    'notifications.manage'
)
ON CONFLICT DO NOTHING;

-- Step 10: Assign permissions to Sales
-- Sales focuses on customer & revenue
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT id FROM roles WHERE name = 'Sales'),
    id 
FROM permissions
WHERE slug IN (
    'auth.login',
    'auth.logout',
    'auth.change-password',
    'users.view',
    'users.update',
    'appointments.view',
    'appointments.manage',
    'appointments.create',
    'offers.view',
    'offers.manage',
    'services.view',
    'dashboard.view',
    'reports.view',
    'gallery.view',
    'courses.view',
    'experts.view'
)
ON CONFLICT DO NOTHING;

COMMIT;

-- Verification: Show remaining roles
SELECT 
    id,
    name,
    is_system_role,
    created_at,
    (SELECT COUNT(*) FROM role_permissions WHERE role_id = r.id) as permission_count
FROM roles r
ORDER BY name;
