const { query } = require('../src/config/db');

async function checkRolesAndPermissions() {
  try {
    console.log('🔍 Checking roles and permissions in database...\n');

    // Get all roles
    console.log('📋 ROLES:');
    console.log('─'.repeat(80));
    const rolesResult = await query(`
      SELECT 
        id,
        name,
        is_system_role,
        created_at
      FROM roles
      ORDER BY name
    `);

    if (rolesResult.rows.length === 0) {
      console.log('❌ No roles found in database\n');
    } else {
      rolesResult.rows.forEach((role, index) => {
        console.log(`${index + 1}. ${role.name} (ID: ${role.id})`);
        console.log(`   System Role: ${role.is_system_role ? 'Yes' : 'No'}`);
        console.log(`   Created: ${role.created_at}`);
        console.log('');
      });
    }

    // Get all permissions
    console.log('\n🔐 PERMISSIONS:');
    console.log('─'.repeat(80));
    const permissionsResult = await query(`
      SELECT 
        id,
        slug,
        description,
        created_at
      FROM permissions
      ORDER BY slug
    `);

    if (permissionsResult.rows.length === 0) {
      console.log('❌ No permissions found in database\n');
    } else {
      console.log(`Total: ${permissionsResult.rows.length} permissions\n`);
      permissionsResult.rows.forEach((perm, index) => {
        console.log(`${index + 1}. ${perm.slug}`);
        if (perm.description) {
          console.log(`   Description: ${perm.description}`);
        }
        console.log('');
      });
    }

    // Get role-permission mappings
    console.log('\n🔗 ROLE-PERMISSION MAPPINGS:');
    console.log('─'.repeat(80));
    const mappingsResult = await query(`
      SELECT 
        r.name as role_name,
        r.is_system_role,
        p.slug as permission_slug,
        p.description as permission_description
      FROM role_permissions rp
      JOIN roles r ON rp.role_id = r.id
      JOIN permissions p ON rp.permission_id = p.id
      ORDER BY r.name, p.slug
    `);

    if (mappingsResult.rows.length === 0) {
      console.log('❌ No role-permission mappings found\n');
    } else {
      // Group by role
      const roleMap = {};
      mappingsResult.rows.forEach((row) => {
        if (!roleMap[row.role_name]) {
          roleMap[row.role_name] = {
            isSystemRole: row.is_system_role,
            permissions: [],
          };
        }
        roleMap[row.role_name].permissions.push({
          slug: row.permission_slug,
          description: row.permission_description,
        });
      });

      Object.entries(roleMap).forEach(([roleName, data]) => {
        console.log(`\n${roleName} ${data.isSystemRole ? '(System Role)' : ''}:`);
        console.log(`  Total Permissions: ${data.permissions.length}`);
        data.permissions.forEach((perm) => {
          console.log(`    ✓ ${perm.slug}`);
        });
      });
    }

    // Summary
    console.log('\n\n📊 SUMMARY:');
    console.log('─'.repeat(80));
    console.log(`Total Roles: ${rolesResult.rows.length}`);
    console.log(`Total Permissions: ${permissionsResult.rows.length}`);
    console.log(`Total Mappings: ${mappingsResult.rows.length}`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error checking roles and permissions:', error);
    process.exit(1);
  }
}

checkRolesAndPermissions();
