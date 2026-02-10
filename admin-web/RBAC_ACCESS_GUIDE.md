# RBAC Access Guide

## How to Access RBAC Management

### Step 1: Login as Admin
- **Email:** `admin@salon.com`
- **Password:** `admin123`

### Step 2: Navigate to Settings
1. Click on **"Settings"** in the sidebar (⚙️ icon)
2. You'll see two main options:
   - **Role Assignment** - Assign roles to users by email
   - **Permission Matrix** - Configure what each role can do

### Step 3: Manage RBAC

#### Option A: Role Assignment (`/settings/roles`)
- Assign roles to users by entering their email addresses
- Supports multiple emails (comma-separated or one per line)
- Users must log out and log back in for changes to take effect
- Available roles: **Admin**, **Expert**, **Manager**, **Sales**

#### Option B: Permission Matrix (`/settings/permissions`)
- Visual matrix showing all roles and permissions
- Check/uncheck permissions for each role
- Click "Save Permissions" to apply changes
- Manage permissions for: **Admin**, **Expert**, **Manager**, **Sales**

## Features

✅ **Email-based Role Assignment** - Assign roles by email address
✅ **Permission Matrix** - Visual interface to manage role permissions
✅ **Automatic Access Control** - Users only see features they have permission for
✅ **Backend Enforcement** - API endpoints also check permissions

## Available Roles

### Admin
- Full system control
- Can manage all users, roles, services, appointments, and system settings
- System role (cannot be deleted)

### Expert
- Senior stylist / trainer role
- Can manage appointments, courses, and view dashboard
- Focused on service delivery and training

### Manager
- Operations and staff management
- Can manage users, services, appointments, experts, and view reports
- Cannot modify system roles or sensitive financial data

### Sales
- Sales and customer relationships
- Can manage appointments, offers, and view customer data
- Focused on revenue generation and customer acquisition

## Troubleshooting

If you can't see the RBAC options:
1. Make sure you're logged in as `admin@salon.com` / `admin123`
2. Check that the Settings menu item is visible in the sidebar
3. Navigate directly to:
   - `/settings/roles` for role assignment
   - `/settings/permissions` for permission matrix
