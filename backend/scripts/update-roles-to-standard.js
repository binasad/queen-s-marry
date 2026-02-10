const { query, transaction } = require('../src/config/db');

async function updateRolesToStandard() {
  try {
    console.log('🔍 Checking current roles in database...\n');

    // Get all current roles
    const currentRoles = await query(`
      SELECT id, name, is_system_role, created_at
      FROM roles
      ORDER BY name
    `);

    console.log('📋 Current Roles:');
    console.log('─'.repeat(80));
    currentRoles.rows.forEach((role, index) => {
      console.log(`${index + 1}. ${role.name} (ID: ${role.id}) - System: ${role.is_system_role}`);
    });
    console.log('');

    // Required roles: Admin, Expert, User, Manager, Sales
    const requiredRoles = ['Admin', 'Expert', 'User', 'Manager', 'Sales'];
    
    console.log('🔄 Updating roles to standard format...\n');

    await transaction(async (client) => {
      // Step 1: Handle duplicate 'admin' and 'Admin'
      const adminRoles = currentRoles.rows.filter(r => r.name.toLowerCase() === 'admin');
      if (adminRoles.length > 1) {
        console.log('⚠️  Found duplicate admin roles. Keeping the system role (Admin)...');
        const systemAdmin = adminRoles.find(r => r.is_system_role);
        const duplicateAdmin = adminRoles.find(r => !r.is_system_role);
        
        if (duplicateAdmin && systemAdmin) {
          // Migrate permissions from duplicate to system Admin
          await client.query(`
            INSERT INTO role_permissions (role_id, permission_id)
            SELECT $1, permission_id
            FROM role_permissions
            WHERE role_id = $2
            ON CONFLICT DO NOTHING
          `, [systemAdmin.id, duplicateAdmin.id]);
          
          // Migrate users from duplicate to system Admin
          await client.query(`
            UPDATE users
            SET role_id = $1
            WHERE role_id = $2
          `, [systemAdmin.id, duplicateAdmin.id]);
          
          // Delete duplicate admin role
          await client.query('DELETE FROM roles WHERE id = $1', [duplicateAdmin.id]);
          console.log(`✅ Removed duplicate 'admin' role (${duplicateAdmin.id})`);
        }
      }

      // Step 2: Rename lowercase roles to proper case
      const roleMappings = {
        'expert': 'Expert',
        'user': 'User',
        'owner': 'Owner',
        'admin': 'Admin' // if lowercase admin still exists
      };

      for (const [oldName, newName] of Object.entries(roleMappings)) {
        const existingLower = await client.query(
          'SELECT id FROM roles WHERE name = $1',
          [oldName]
        );
        const existingUpper = await client.query(
          'SELECT id FROM roles WHERE name = $1',
          [newName]
        );

        if (existingLower.rows.length > 0 && existingUpper.rows.length === 0) {
          // Rename lowercase to uppercase
          await client.query(
            'UPDATE roles SET name = $1 WHERE name = $2',
            [newName, oldName]
          );
          console.log(`✅ Renamed '${oldName}' to '${newName}'`);
        } else if (existingLower.rows.length > 0 && existingUpper.rows.length > 0) {
          // Both exist - merge and delete lowercase
          const lowerId = existingLower.rows[0].id;
          const upperId = existingUpper.rows[0].id;
          
          // Migrate permissions
          await client.query(`
            INSERT INTO role_permissions (role_id, permission_id)
            SELECT $1, permission_id
            FROM role_permissions
            WHERE role_id = $2
            ON CONFLICT DO NOTHING
          `, [upperId, lowerId]);
          
          // Migrate users
          await client.query(`
            UPDATE users
            SET role_id = $1
            WHERE role_id = $2
          `, [upperId, lowerId]);
          
          // Delete lowercase
          await client.query('DELETE FROM roles WHERE id = $1', [lowerId]);
          console.log(`✅ Merged '${oldName}' into '${newName}' and removed duplicate`);
        }
      }

      // Step 3: Create missing required roles
      for (const roleName of requiredRoles) {
        const exists = await client.query(
          'SELECT id FROM roles WHERE name = $1',
          [roleName]
        );

        if (exists.rows.length === 0) {
          const isSystemRole = ['Admin', 'User'].includes(roleName);
          await client.query(
            'INSERT INTO roles (name, is_system_role) VALUES ($1, $2)',
            [roleName, isSystemRole]
          );
          console.log(`✅ Created missing role: ${roleName}`);
        }
      }

      // Step 4: Ensure proper capitalization for all roles
      await client.query(`
        UPDATE roles
        SET name = INITCAP(name)
        WHERE name != INITCAP(name)
        AND name NOT IN ('Admin', 'Expert', 'User', 'Manager', 'Sales', 'Owner')
      `);
    });

    // Final check
    console.log('\n📋 Final Roles:');
    console.log('─'.repeat(80));
    const finalRoles = await query(`
      SELECT id, name, is_system_role,
        (SELECT COUNT(*) FROM role_permissions WHERE role_id = r.id) as permission_count
      FROM roles r
      ORDER BY name
    `);

    finalRoles.rows.forEach((role) => {
      console.log(`✓ ${role.name} (${role.permission_count} permissions) - System: ${role.is_system_role}`);
    });

    console.log('\n✅ Role update completed successfully!');
    console.log('\n📝 Required roles status:');
    for (const roleName of requiredRoles) {
      const exists = await query('SELECT id FROM roles WHERE name = $1', [roleName]);
      console.log(`   ${exists.rows.length > 0 ? '✓' : '✗'} ${roleName}`);
    }

  } catch (error) {
    console.error('❌ Error updating roles:', error);
    process.exit(1);
  }
}

updateRolesToStandard().then(() => process.exit(0));
