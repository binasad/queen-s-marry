/**
 * Migrate existing guest users (is_guest=true) from Customer role to Guest role.
 * Run: node scripts/migrate-guests-to-guest-role.js
 */
const { query } = require('../src/config/db');

async function migrate() {
  try {
    // Ensure Guest role exists
    let guestRole = await query('SELECT id FROM roles WHERE name = $1', ['Guest']);
    if (guestRole.rows.length === 0) {
      await query(
        'INSERT INTO roles (name, is_system_role) VALUES ($1, $2) RETURNING id',
        ['Guest', false]
      );
      guestRole = await query('SELECT id FROM roles WHERE name = $1', ['Guest']);
    }
    const guestRoleId = guestRole.rows[0].id;

    const customerRole = await query('SELECT id FROM roles WHERE name = $1', ['Customer']);
    if (customerRole.rows.length === 0) {
      console.log('No Customer role found. Nothing to migrate.');
      process.exit(0);
    }
    const customerRoleId = customerRole.rows[0].id;

    const result = await query(
      `UPDATE users SET role_id = $1 WHERE is_guest = true AND role_id = $2 RETURNING id`,
      [guestRoleId, customerRoleId]
    );

    console.log(`✅ Migrated ${result.rows.length} guest user(s) to Guest role.`);
  } catch (err) {
    console.error('❌ Migration error:', err.message);
    process.exit(1);
  }
  process.exit(0);
}

migrate();
