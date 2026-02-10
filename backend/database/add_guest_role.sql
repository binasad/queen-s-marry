-- Migration: Add Guest Role and Permissions
-- This creates a dedicated GUEST role with limited permissions

-- 1. Insert Guest role if it doesn't exist
INSERT INTO roles (name, is_system_role) 
VALUES ('Guest', TRUE) 
ON CONFLICT (name) DO NOTHING;

-- 2. Add is_guest column to users table to easily identify guest accounts
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT FALSE;

-- 3. Create guest-specific permissions (read-only access)
INSERT INTO permissions (slug, description) VALUES
    ('services.view', 'View available services'),
    ('offers.view', 'View current offers'),
    ('courses.view', 'View available courses'),
    ('experts.view', 'View expert profiles')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'Guest' 
AND p.slug IN ('services.view', 'offers.view', 'courses.view', 'experts.view')
ON CONFLICT DO NOTHING;

-- Ensure Guest role never has 'courses.apply' permission
DELETE FROM role_permissions
USING roles r, permissions p
WHERE r.name = 'Guest'
AND p.slug = 'courses.apply'
AND role_permissions.role_id = r.id
AND role_permissions.permission_id = p.id;

-- 5. Ensure User role has all necessary permissions for full functionality
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id 
FROM roles r, permissions p 
WHERE r.name = 'User' 
AND p.slug IN (
    'services.view', 
    'offers.view', 
    'courses.view', 
    'experts.view',
    'appointments.create',
    'appointments.view_own',
    'profile.update',
    'courses.apply'
)
ON CONFLICT DO NOTHING;

-- Note: Run this migration with: psql -d your_database -f add_guest_role.sql
