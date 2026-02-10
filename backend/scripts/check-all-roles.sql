-- Check all roles in the database
SELECT 
    id,
    name,
    is_system_role,
    created_at,
    (SELECT COUNT(*) FROM role_permissions WHERE role_id = r.id) as permission_count
FROM roles r
ORDER BY name;

-- Check if we have the required roles (Admin, Expert, User, Manager, Sales)
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM roles WHERE name = 'Admin') THEN '✓ Admin exists'
        ELSE '✗ Admin MISSING'
    END as admin_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM roles WHERE name = 'Expert') THEN '✓ Expert exists'
        ELSE '✗ Expert MISSING'
    END as expert_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM roles WHERE name = 'User') THEN '✓ User exists'
        ELSE '✗ User MISSING'
    END as user_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM roles WHERE name = 'Manager') THEN '✓ Manager exists'
        ELSE '✗ Manager MISSING'
    END as manager_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM roles WHERE name = 'Sales') THEN '✓ Sales exists'
        ELSE '✗ Sales MISSING'
    END as sales_status;

-- Check for duplicate roles (case-insensitive)
SELECT 
    LOWER(name) as role_name_lower,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as actual_names,
    STRING_AGG(id::text, ', ') as ids
FROM roles
GROUP BY LOWER(name)
HAVING COUNT(*) > 1;
