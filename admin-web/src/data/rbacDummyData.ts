// Salon app RBAC demo data, aligned with backend roles/permissions

export const AVAILABLE_ROLES = [
  { id: 'Admin', name: 'Admin', description: 'Full system control' },
  { id: 'Expert', name: 'Expert', description: 'Senior stylist / trainer' },
  { id: 'Manager', name: 'Manager', description: 'Operations and staff management' },
  { id: 'Sales', name: 'Sales', description: 'Sales and customer relationships' },
];

export const AVAILABLE_PERMISSIONS = [
  // --- Users & Roles ---
  { id: 'users.view', name: 'users.view', label: 'View user profiles', group: 'Users & Roles' },
  { id: 'users.create', name: 'users.create', label: 'Create users', group: 'Users & Roles' },
  { id: 'users.update', name: 'users.update', label: 'Update users', group: 'Users & Roles' },
  { id: 'users.delete', name: 'users.delete', label: 'Delete users', group: 'Users & Roles' },
  { id: 'users.assign-role', name: 'users.assign-role', label: 'Assign roles', group: 'Users & Roles' },

  // --- Services & Categories ---
  { id: 'services.view', name: 'services.view', label: 'View services', group: 'Services' },
  { id: 'services.manage', name: 'services.manage', label: 'Manage services', group: 'Services' },
  { id: 'categories.manage', name: 'categories.manage', label: 'Manage categories', group: 'Services' },

  // --- Appointments ---
  { id: 'appointments.view', name: 'appointments.view', label: 'View appointments', group: 'Appointments' },
  { id: 'appointments.create', name: 'appointments.create', label: 'Create appointments', group: 'Appointments' },
  { id: 'appointments.manage', name: 'appointments.manage', label: 'Manage appointments', group: 'Appointments' },
  { id: 'appointments.cancel', name: 'appointments.cancel', label: 'Cancel appointments', group: 'Appointments' },
  { id: 'appointments.manage_all', name: 'appointments.manage_all', label: 'Manage all appointments', group: 'Appointments' },

  // --- Offers & Courses ---
  { id: 'offers.view', name: 'offers.view', label: 'View offers', group: 'Marketing' },
  { id: 'offers.manage', name: 'offers.manage', label: 'Manage offers', group: 'Marketing' },
  { id: 'courses.view', name: 'courses.view', label: 'View courses', group: 'Training' },
  { id: 'courses.manage', name: 'courses.manage', label: 'Manage courses', group: 'Training' },

  // --- Experts & Gallery ---
  { id: 'experts.view', name: 'experts.view', label: 'View experts', group: 'Experts' },
  { id: 'experts.manage', name: 'experts.manage', label: 'Manage experts', group: 'Experts' },
  { id: 'gallery.view', name: 'gallery.view', label: 'View gallery', group: 'Gallery' },
  { id: 'gallery.manage', name: 'gallery.manage', label: 'Manage gallery', group: 'Gallery' },

  // --- Support, Dashboard, Reports ---
  { id: 'support.view', name: 'support.view', label: 'View support tickets', group: 'Support' },
  { id: 'support.manage', name: 'support.manage', label: 'Manage support tickets', group: 'Support' },
  { id: 'dashboard.view', name: 'dashboard.view', label: 'View dashboard', group: 'Analytics' },
  { id: 'reports.view', name: 'reports.view', label: 'View reports', group: 'Analytics' },
];

// Default permission mapping (demo only, mirrors backend intent)
export const INITIAL_RBAC_MATRIX: Record<string, string[]> = {
  Admin: [
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'users.assign-role',
    'services.view',
    'services.manage',
    'categories.manage',
    'appointments.view',
    'appointments.create',
    'appointments.manage',
    'appointments.cancel',
    'appointments.manage_all',
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
  ],
  Expert: [
    'auth.login',
    'auth.logout',
    'auth.change-password',
    'appointments.view',
    'appointments.create',
    'appointments.manage',
    'appointments.cancel',
    'courses.view',
    'courses.manage',
    'offers.view',
    'offers.manage',
    'services.view',
    'experts.view',
    'dashboard.view',
    'users.view',
  ],
  Manager: [
    'users.view',
    'users.create',
    'users.update',
    'services.view',
    'services.manage',
    'categories.manage',
    'appointments.view',
    'appointments.create',
    'appointments.manage',
    'appointments.cancel',
    'appointments.manage_all',
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
  ],
  Sales: [
    'users.view',
    'users.update',
    'appointments.view',
    'appointments.create',
    'appointments.manage',
    'offers.view',
    'offers.manage',
    'services.view',
    'courses.view',
    'experts.view',
    'gallery.view',
    'dashboard.view',
    'reports.view',
  ],
};
console.log("ok");