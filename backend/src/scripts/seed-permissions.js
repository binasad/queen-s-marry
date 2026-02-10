const { query } = require('../config/db');

const permissions = [
  // Authentication & User Management
  { slug: 'auth.login', description: 'Login to system' },
  { slug: 'auth.logout', description: 'Logout from system' },
  { slug: 'auth.change-password', description: 'Change own password' },

  // User Management
  { slug: 'users.view', description: 'View user profiles' },
  { slug: 'users.create', description: 'Create user accounts' },
  { slug: 'users.update', description: 'Update user profiles' },
  { slug: 'users.delete', description: 'Delete user accounts' },
  { slug: 'users.assign-role', description: 'Assign roles to users' },

  // Role Management
  { slug: 'roles.view', description: 'View roles and permissions' },
  { slug: 'roles.create', description: 'Create new roles' },
  { slug: 'roles.update', description: 'Update roles and permissions' },
  { slug: 'roles.delete', description: 'Delete roles' },

  // Services Management
  { slug: 'services.view', description: 'View services' },
  { slug: 'services.manage', description: 'Create, edit, delete services' },
  { slug: 'categories.manage', description: 'Manage service categories' },

  // Appointments Management
  { slug: 'appointments.view', description: 'View appointments' },
  { slug: 'appointments.manage', description: 'Manage appointments' },
  { slug: 'appointments.cancel', description: 'Cancel appointments' },

  // Offers Management
  { slug: 'offers.view', description: 'View offers and promotions' },
  { slug: 'offers.manage', description: 'Create, edit, and delete offers' },

  // Courses Management
  { slug: 'courses.view', description: 'View training courses' },
  { slug: 'courses.manage', description: 'Create, edit, delete courses' },

  // Experts Management
  { slug: 'experts.view', description: 'View experts/stylists' },
  { slug: 'experts.manage', description: 'Create, edit, delete experts' },

  // Gallery Management
  { slug: 'gallery.view', description: 'View gallery images' },
  { slug: 'gallery.manage', description: 'Upload, edit, delete gallery images' },

  // Support Management
  { slug: 'support.view', description: 'View support tickets' },
  { slug: 'support.manage', description: 'Manage support tickets' },

  // Dashboard & Reports
  { slug: 'dashboard.view', description: 'View dashboard and analytics' },
  { slug: 'reports.view', description: 'View detailed reports' },

  // Notifications
  { slug: 'notifications.send', description: 'Send notifications' },
  { slug: 'notifications.manage', description: 'Manage notification settings' },
];

const roles = [
  {
    name: 'user',
    permissions: [
      'auth.login',
      'auth.logout',
      'auth.change-password',
      'appointments.view',
      'courses.view',
      'offers.view',
      'gallery.view',
    ],
  },
  {
    name: 'expert',
    permissions: [
      'auth.login',
      'auth.logout',
      'auth.change-password',
      'appointments.view',
      'appointments.manage',
      'users.view',
      'dashboard.view',
    ],
  },
  {
    name: 'admin',
    permissions: [
      'auth.login',
      'auth.logout',
      'auth.change-password',
      'users.view',
      'users.create',
      'users.update',
      'users.delete',
      'users.assign-role',
      'roles.view',
      'services.view',
      'services.manage',
      'categories.manage',
      'appointments.view',
      'appointments.manage',
      'appointments.cancel',
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
      'notifications.manage',
    ],
  },
  {
    name: 'owner',
    permissions: [
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
      'notifications.manage',
    ],
  },
];

async function seedPermissions() {
  try {
    console.log('🌱 Seeding permissions and roles...');

    // Insert permissions
    console.log('📝 Inserting permissions...');
    for (const permission of permissions) {
      await query(
        'INSERT INTO permissions (slug, description) VALUES ($1, $2) ON CONFLICT (slug) DO NOTHING',
        [permission.slug, permission.description]
      );
    }
    console.log(`✅ Inserted ${permissions.length} permissions`);

    // Insert roles
    console.log('👥 Inserting roles...');
    for (const role of roles) {
      const roleResult = await query(
        'INSERT INTO roles (name) VALUES ($1) ON CONFLICT (name) DO NOTHING RETURNING id',
        [role.name]
      );

      let roleId;
      if (roleResult.rows.length === 0) {
        // Role already exists, get its ID
        const existingRole = await query('SELECT id FROM roles WHERE name = $1', [role.name]);
        roleId = existingRole.rows[0].id;
      } else {
        roleId = roleResult.rows[0].id;
      }
      console.log(`📋 Processing role: ${role.name} (ID: ${roleId})`);

      // Assign permissions to role
      for (const permissionSlug of role.permissions) {
        await query(
          `INSERT INTO role_permissions (role_id, permission_id)
           SELECT $1, p.id FROM permissions p WHERE p.slug = $2
           ON CONFLICT (role_id, permission_id) DO NOTHING`,
          [roleId, permissionSlug]
        );
      }
      console.log(`🔗 Assigned ${role.permissions.length} permissions to ${role.name}`);
    }

    console.log('🎉 Permissions and roles seeding completed successfully!');
  } catch (error) {
    console.error('❌ Error seeding permissions:', error);
    process.exit(1);
  }
}

// Run the seeding
seedPermissions();