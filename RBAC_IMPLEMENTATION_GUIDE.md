# RBAC (Role-Based Access Control) Implementation Guide

## Overview

This document explains how Role-Based Access Control (RBAC) is implemented across the backend API and admin-web frontend.

---

## 📊 Database Schema

### Core Tables

```sql
-- Permissions table (system capabilities)
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(150) UNIQUE NOT NULL,  -- e.g., "appointments.view"
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles table (dynamic, admin-manageable)
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,  -- e.g., "Receptionist"
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Role to permission mapping (many-to-many)
CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Users table references roles
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    -- ... other fields
);
```

### Default Permissions

```sql
-- System permissions seeded on database initialization
INSERT INTO permissions (slug, description) VALUES 
    ('users.view', 'View user profiles'),
    ('users.manage', 'Create/Delete users'),
    ('services.manage', 'Create/Update services'),
    ('appointments.create', 'Book appointments'),
    ('appointments.manage_all', 'View and cancel ANY appointment'),
    ('dashboard.view', 'View financial stats'),
    ('roles.manage', 'Create roles and assign permissions'),
    ('roles.view', 'View roles and permissions');
```

### Default Roles

- **Owner**: Gets ALL permissions (system role)
- **Admin**: Gets most permissions (system role)
- **User**: Only basic booking permissions (system role)

---

## 🔧 Backend Implementation

### 1. Authentication Middleware (`auth.middleware.js`)

**Location**: `backend/src/middlewares/auth.middleware.js`

**Function**: Verifies JWT token and loads user with role + permissions

```javascript
const auth = async (req, res, next) => {
  // 1. Extract token from Authorization header
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  // 2. Verify JWT token
  const decoded = verifyAccessToken(token);
  
  // 3. Load user with role and permissions from database
  const result = await query(`
    SELECT
      u.id,
      u.email,
      u.email_verified,
      u.role_id,
      r.name AS role_name,
      COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
    FROM users u
    LEFT JOIN roles r ON u.role_id = r.id
    LEFT JOIN role_permissions rp ON rp.role_id = r.id
    LEFT JOIN permissions p ON p.id = rp.permission_id
    WHERE u.id = $1
    GROUP BY u.id, r.id
  `, [decoded.id]);
  
  // 4. Attach user to request object
  req.user = {
    id: user.id,
    email: user.email,
    roleId: user.role_id,
    roleName: user.role_name,
    permissions: user.permissions || [],  // Array of permission slugs
    email_verified: user.email_verified,
  };
  
  next();
};
```

**Usage**: Applied to protected routes
```javascript
router.get('/protected-route', auth, controller.handler);
```

---

### 2. Permission Middleware (`role.middleware.js`)

**Location**: `backend/src/middlewares/role.middleware.js`

#### `checkPermission(permissions)`

Checks if user has required permission(s).

```javascript
const checkPermission = (permissions) => {
  return (req, res, next) => {
    const required = Array.isArray(permissions) ? permissions : [permissions];
    const userPerms = req.user.permissions || [];
    const hasPerm = required.every((perm) => userPerms.includes(perm));
    
    if (!hasPerm) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Insufficient permissions.',
      });
    }
    next();
  };
};
```

**Usage**:
```javascript
// Single permission
router.get('/users', auth, checkPermission('users.view'), controller.listUsers);

// Multiple permissions (ALL required)
router.post('/users', auth, checkPermission(['users.view', 'users.manage']), controller.createUser);
```

#### `hasRole(roles)`

Checks if user has specific role name(s).

```javascript
const hasRole = (roles) => {
  return (req, res, next) => {
    const allowedRoles = Array.isArray(roles) ? roles : [roles];
    if (allowedRoles.includes(req.user.roleName)) {
      return next();
    }
    return res.status(403).json({
      success: false,
      message: 'Access denied. Insufficient role.',
    });
  };
};
```

**Usage**:
```javascript
router.delete('/admin-only', auth, hasRole('Owner'), controller.delete);
```

---

### 3. Roles API Endpoints

**Location**: `backend/src/modules/roles/roles.routes.js`

**Base Path**: `/api/v1/roles`

#### Available Endpoints

| Method | Endpoint | Auth | Permission | Description |
|--------|----------|------|------------|-------------|
| GET | `/permissions` | ✅ | `roles.view` | List all permissions |
| GET | `/roles` | ✅ | `roles.view` | List all roles with their permissions |
| POST | `/roles` | ✅ | `roles.manage` | Create a new role |
| PUT | `/roles/:id/permissions` | ✅ | `roles.manage` | Update role permissions |

#### Example: List Roles

**Request**:
```http
GET /api/v1/roles/roles
Authorization: Bearer <token>
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-here",
      "name": "Receptionist",
      "is_system_role": false,
      "permissions": ["appointments.view", "appointments.create", "users.view"]
    },
    {
      "id": "uuid-here",
      "name": "Owner",
      "is_system_role": true,
      "permissions": ["users.view", "users.manage", "services.manage", ...]
    }
  ]
}
```

#### Example: Create Role

**Request**:
```http
POST /api/v1/roles/roles
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Receptionist",
  "permissions": ["appointments.view", "appointments.create", "users.view"]
}
```

**Response**:
```json
{
  "success": true,
  "message": "Role created successfully.",
  "data": {
    "id": "uuid-here",
    "name": "Receptionist",
    "is_system_role": false
  }
}
```

#### Example: Update Role Permissions

**Request**:
```http
PUT /api/v1/roles/roles/:roleId/permissions
Authorization: Bearer <token>
Content-Type: application/json

{
  "permissions": ["appointments.view", "appointments.create", "appointments.manage_all"]
}
```

**Response**:
```json
{
  "success": true,
  "message": "Permissions updated.",
  "data": {
    "id": "uuid-here",
    "name": "Receptionist",
    "is_system_role": false,
    "permissions": ["appointments.view", "appointments.create", "appointments.manage_all"]
  }
}
```

---

### 4. Roles Controller (`roles.controller.js`)

**Location**: `backend/src/modules/roles/roles.controller.js`

**Methods**:

1. **`listPermissions()`** - Returns all available permissions
2. **`listRoles()`** - Returns all roles with their permissions (aggregated)
3. **`createRole(name, permissions)`** - Creates new role and assigns permissions
4. **`updateRolePermissions(roleId, permissions)`** - Updates permissions for a role

**Key Implementation Details**:

- Uses PostgreSQL `array_agg()` to aggregate permissions per role
- Validates permission slugs exist before assigning
- Uses transactions for atomic updates
- System roles (`is_system_role = true`) can be protected from deletion

---

## 🎨 Admin-Web Frontend Implementation

### Current State

**Location**: `admin-web/src/`

#### 1. Auth Store (`store/authStore.ts`)

Currently stores basic user info but **doesn't include permissions**:

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  role: string;  // Only role name, no permissions
  profileImage?: string;
}
```

**Issue**: Admin-web doesn't fetch or store user permissions yet.

#### 2. Auth Guard (`components/AuthGuard.tsx`)

Currently only checks role name:

```typescript
if (user.role !== 'admin' && user.role !== 'owner') {
  router.push('/unauthorized');
}
```

**Issue**: Hardcoded role check, doesn't use permission-based access.

#### 3. API Client (`lib/api.ts`)

**Current**: No RBAC API methods defined.

**Missing**:
- `rolesAPI.getPermissions()`
- `rolesAPI.getRoles()`
- `rolesAPI.createRole()`
- `rolesAPI.updateRolePermissions()`

---

## 🚀 How to Implement RBAC in Admin-Web

### Step 1: Update Auth Store

**File**: `admin-web/src/store/authStore.ts`

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  roleId: string;
  permissions: string[];  // Add permissions array
  profileImage?: string;
}

interface AuthStore {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (userData: Partial<User>) => void;
  hasPermission: (permission: string | string[]) => boolean;  // Add helper
  hasRole: (role: string | string[]) => boolean;  // Add helper
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      
      login: (user, token) => {
        localStorage.setItem('token', token);
        set({ user, token, isAuthenticated: true });
      },
      
      logout: () => {
        localStorage.removeItem('token');
        set({ user: null, token: null, isAuthenticated: false });
      },
      
      updateUser: (userData) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...userData } : null,
        })),
      
      // Check if user has permission(s)
      hasPermission: (permission) => {
        const user = get().user;
        if (!user || !user.permissions) return false;
        
        const required = Array.isArray(permission) ? permission : [permission];
        return required.every((perm) => user.permissions.includes(perm));
      },
      
      // Check if user has role(s)
      hasRole: (role) => {
        const user = get().user;
        if (!user) return false;
        
        const allowedRoles = Array.isArray(role) ? role : [role];
        return allowedRoles.includes(user.role);
      },
    }),
    { name: 'auth-storage' }
  )
);
```

### Step 2: Update Login to Fetch Permissions

**File**: `admin-web/src/app/login/page.tsx`

```typescript
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  setIsLoading(true);

  try {
    // Login
    const loginResponse = await authAPI.login({ email, password });
    const { data } = loginResponse.data;
    
    // Store token
    localStorage.setItem('token', data.accessToken);
    
    // Fetch user profile (includes permissions)
    const profileResponse = await authAPI.getProfile();
    const userData = profileResponse.data.data.user;
    
    // Login with full user data including permissions
    login({
      id: userData.id,
      name: userData.name,
      email: userData.email,
      role: userData.role?.name || 'User',
      roleId: userData.role_id,
      permissions: userData.permissions || [],  // From backend
      profileImage: userData.profile_image_url,
    }, data.accessToken);
    
    toast.success('Login successful!');
    router.push('/dashboard');
  } catch (error) {
    toast.error('Login failed');
  } finally {
    setIsLoading(false);
  }
};
```

### Step 3: Add RBAC API Methods

**File**: `admin-web/src/lib/api.ts`

```typescript
// Roles & Permissions API
export const rolesAPI = {
  // Get all available permissions
  getPermissions: () => api.get('/roles/permissions'),
  
  // Get all roles with permissions
  getRoles: () => api.get('/roles/roles'),
  
  // Create a new role
  createRole: (data: { name: string; permissions: string[] }) =>
    api.post('/roles/roles', data),
  
  // Update role permissions
  updateRolePermissions: (roleId: string, permissions: string[]) =>
    api.put(`/roles/roles/${roleId}/permissions`, { permissions }),
};
```

### Step 4: Create Permission-Based Guard Component

**File**: `admin-web/src/components/PermissionGuard.tsx`

```typescript
'use client';

import { useAuthStore } from '@/store/authStore';

interface PermissionGuardProps {
  children: React.ReactNode;
  permission: string | string[];
  fallback?: React.ReactNode;
}

export default function PermissionGuard({ 
  children, 
  permission, 
  fallback = null 
}: PermissionGuardProps) {
  const hasPermission = useAuthStore((state) => state.hasPermission);
  
  if (!hasPermission(permission)) {
    return <>{fallback}</>;
  }
  
  return <>{children}</>;
}
```

**Usage**:
```tsx
<PermissionGuard permission="users.manage">
  <button>Delete User</button>
</PermissionGuard>

<PermissionGuard 
  permission={['appointments.view', 'appointments.manage_all']}
  fallback={<p>You don't have permission</p>}
>
  <AppointmentsTable />
</PermissionGuard>
```

### Step 5: Update Auth Guard to Use Permissions

**File**: `admin-web/src/components/AuthGuard.tsx`

```typescript
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';

interface AuthGuardProps {
  children: React.ReactNode;
  requiredPermission?: string | string[];
  requiredRole?: string | string[];
}

export default function AuthGuard({ 
  children, 
  requiredPermission,
  requiredRole 
}: AuthGuardProps) {
  const { isAuthenticated, user, hasPermission, hasRole } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    
    // Check role if specified
    if (requiredRole && !hasRole(requiredRole)) {
      router.push('/unauthorized');
      return;
    }
    
    // Check permission if specified
    if (requiredPermission && !hasPermission(requiredPermission)) {
      router.push('/unauthorized');
      return;
    }
  }, [isAuthenticated, user, requiredPermission, requiredRole, router]);

  if (!isAuthenticated || !user) {
    return null;
  }
  
  // Additional checks
  if (requiredRole && !hasRole(requiredRole)) {
    return null;
  }
  
  if (requiredPermission && !hasPermission(requiredPermission)) {
    return null;
  }

  return <>{children}</>;
}
```

**Usage**:
```tsx
// Protect by role
<AuthGuard requiredRole="Owner">
  <AdminPanel />
</AuthGuard>

// Protect by permission
<AuthGuard requiredPermission="users.manage">
  <UserManagement />
</AuthGuard>

// Protect by both
<AuthGuard requiredRole="Owner" requiredPermission="roles.manage">
  <RoleManagement />
</AuthGuard>
```

### Step 6: Create Roles Management Page

**File**: `admin-web/src/app/settings/roles/page.tsx`

```typescript
'use client';

import { useEffect, useState } from 'react';
import { rolesAPI } from '@/lib/api';
import PermissionGuard from '@/components/PermissionGuard';

export default function RolesPage() {
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [rolesRes, permsRes] = await Promise.all([
        rolesAPI.getRoles(),
        rolesAPI.getPermissions(),
      ]);
      setRoles(rolesRes.data.data);
      setPermissions(permsRes.data.data);
    } catch (error) {
      console.error('Failed to load roles:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateRole = async (name: string, selectedPermissions: string[]) => {
    try {
      await rolesAPI.createRole({ name, permissions: selectedPermissions });
      await loadData();
      toast.success('Role created successfully');
    } catch (error) {
      toast.error('Failed to create role');
    }
  };

  const handleUpdatePermissions = async (roleId: string, selectedPermissions: string[]) => {
    try {
      await rolesAPI.updateRolePermissions(roleId, selectedPermissions);
      await loadData();
      toast.success('Permissions updated');
    } catch (error) {
      toast.error('Failed to update permissions');
    }
  };

  // ... render UI
}
```

---

## 📝 Permission Naming Convention

Follow this pattern: `{resource}.{action}`

**Examples**:
- `users.view` - View user profiles
- `users.manage` - Create/delete users
- `appointments.view` - View appointments
- `appointments.create` - Book appointments
- `appointments.manage_all` - Manage any appointment
- `services.manage` - Create/update services
- `roles.view` - View roles
- `roles.manage` - Create roles and assign permissions
- `dashboard.view` - View dashboard stats

---

## 🔒 Example: Protecting Routes

### Backend Example

```javascript
// Only users with 'users.manage' permission can create users
router.post(
  '/users',
  auth,
  checkPermission('users.manage'),
  usersController.createUser
);

// Only Owner role can delete users
router.delete(
  '/users/:id',
  auth,
  hasRole('Owner'),
  usersController.deleteUser
);

// Multiple permissions required
router.put(
  '/appointments/:id/status',
  auth,
  checkPermission(['appointments.view', 'appointments.manage_all']),
  appointmentsController.updateStatus
);
```

### Frontend Example

```tsx
// Hide button if user doesn't have permission
<PermissionGuard permission="users.manage">
  <button onClick={handleDelete}>Delete User</button>
</PermissionGuard>

// Protect entire page
<AuthGuard requiredPermission="roles.manage">
  <RolesManagementPage />
</AuthGuard>

// Conditional rendering
{hasPermission('dashboard.view') && (
  <DashboardStats />
)}
```

---

## ✅ Summary

### Backend ✅ (Fully Implemented)

- ✅ Database schema with roles, permissions, and mappings
- ✅ Authentication middleware loads user permissions
- ✅ Permission middleware (`checkPermission`)
- ✅ Role middleware (`hasRole`)
- ✅ Roles API endpoints (CRUD operations)
- ✅ Validation and error handling

### Admin-Web ⚠️ (Needs Implementation)

- ⚠️ Auth store doesn't store permissions
- ⚠️ Login doesn't fetch permissions
- ⚠️ No RBAC API methods
- ⚠️ No permission-based guards
- ⚠️ Hardcoded role checks
- ⚠️ No roles management UI

### Next Steps for Admin-Web

1. Update `authStore.ts` to include permissions
2. Update login flow to fetch permissions
3. Add `rolesAPI` methods to `api.ts`
4. Create `PermissionGuard` component
5. Update `AuthGuard` to use permissions
6. Create roles management page
7. Replace hardcoded role checks with permission checks

---

## 📚 Related Files

- **Backend**:
  - `backend/src/middlewares/auth.middleware.js` - Auth + permission loading
  - `backend/src/middlewares/role.middleware.js` - Permission/role checks
  - `backend/src/modules/roles/roles.controller.js` - Roles CRUD
  - `backend/src/modules/roles/roles.routes.js` - Routes
  - `backend/database/schema.sql` - Database schema

- **Admin-Web**:
  - `admin-web/src/store/authStore.ts` - Auth state (needs update)
  - `admin-web/src/lib/api.ts` - API client (needs RBAC methods)
  - `admin-web/src/components/AuthGuard.tsx` - Route protection (needs update)
