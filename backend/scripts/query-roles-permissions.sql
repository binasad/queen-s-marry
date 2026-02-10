-- Query to check all roles and permissions in the database
-- Run this in your PostgreSQL database

-- 1. Get all roles
SELECT 
    id,
    name,
    is_system_role,
    created_at
FROM roles
ORDER BY name;

-- 2. Get all permissions
SELECT 
    id,
    slug,
    description,
    created_at
FROM permissions
ORDER BY slug;

-- 3. Get role-permission mappings (detailed view)
SELECT 
    r.name as role_name,
    r.is_system_role,
    COUNT(p.id) as permission_count,
    STRING_AGG(p.slug, ', ' ORDER BY p.slug) as permissions
FROM roles r
LEFT JOIN role_permissions rp ON r.id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.id
GROUP BY r.id, r.name, r.is_system_role
ORDER BY r.name;

-- 4. Detailed role-permission mapping (one row per permission)
SELECT 
    r.name as role_name,
    r.is_system_role,
    p.slug as permission_slug,
    p.description as permission_description
FROM role_permissions rp
JOIN roles r ON rp.role_id = r.id
JOIN permissions p ON rp.permission_id = p.id
ORDER BY r.name, p.slug;

-- 5. Summary counts
SELECT 
    (SELECT COUNT(*) FROM roles) as total_roles,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM role_permissions) as total_mappings;
