# Admin Workflow & Template Design Documentation

## Table of Contents
1. [Admin Workflow](#admin-workflow)
2. [Template Design](#template-design)

---

## Admin Workflow

### 1. Authentication & Access Control

#### Login Process
- **Step 1:** Admin navigates to login page (`/login`)
- **Step 2:** Enters credentials:
  - **Hardcoded Admin:** `admin@salon.com` / `admin123` (bypasses API, grants full access)
  - **Regular Users:** Email and password (authenticated via backend API)
- **Step 3:** System validates credentials and loads user profile with permissions
- **Step 4:** User is redirected to Dashboard (`/dashboard`)
- **Step 5:** Sidebar navigation is dynamically filtered based on user's assigned permissions

#### Permission-Based Access
- Each menu item in the sidebar requires a specific permission
- If user lacks permission, menu item is hidden
- Pages are protected by `AuthGuard` and `PermissionGuard` components
- Backend API also enforces permissions (double-layer security)

---

### 2. Dashboard Overview

#### Purpose
Central hub displaying key metrics and quick access to important information.

#### Workflow Steps
1. **View Statistics:**
   - Total Revenue (with percentage change)
   - Total Appointments (with trend indicator)
   - Total Customers (with growth metric)
   - Active Services count

2. **Review Revenue Chart:**
   - Weekly revenue trend visualization
   - Day-by-day breakdown
   - Quick insights into peak days

3. **Check Recent Appointments:**
   - View latest appointments with status
   - See customer names, services, and times
   - Quick access to appointment management

4. **Monitor Top Services:**
   - See most booked services
   - Revenue per service
   - Booking frequency

5. **Staff Performance:**
   - View expert/staff performance metrics
   - Service completion rates

---

### 3. Service Management

#### Purpose
Manage salon services catalog (create, edit, delete, view).

#### Workflow Steps

**Adding a New Service:**
1. Navigate to Services page (`/services`)
2. Click "+ Add Service" button
3. Fill in the modal form:
   - Select Category (required dropdown)
   - Enter Service Name (required)
   - Add Description (optional textarea)
   - Set Price in Rs. (required, decimal)
   - Set Duration in minutes (required, integer)
   - Add Image URL (optional)
   - Add Tags (comma-separated, optional)
4. Click "Create Service"
5. Service appears in the grid immediately

**Editing a Service:**
1. Click "Edit" button on any service card
2. Modal opens with pre-filled form data
3. Modify any fields
4. Click "Update Service"
5. Changes are saved and reflected

**Deleting a Service:**
1. Click "Delete" button on service card
2. Confirm deletion in popup
3. Service is removed from catalog

**Searching Services:**
- Use search bar to filter services by name or description
- Results update in real-time as you type

---

### 4. Customer Management

#### Purpose
View and manage customer accounts.

#### Workflow Steps
1. Navigate to Customers page (`/customers`)
2. View customer list with:
   - Name, Email, Phone
   - Role assignment
   - Account status
3. **Search:** Filter customers by name or email
4. **Filter by Role:** Dropdown to filter by user role
5. **Delete Customer:** Remove customer account (with confirmation)

---

### 5. Course Management

#### Purpose
Manage training courses offered by the salon.

#### Workflow Steps

**Adding a Course:**
1. Navigate to Courses page (`/courses`)
2. Click "+ Add Course"
3. Fill form:
   - Title (required)
   - Description (optional)
   - Duration (e.g., "3 months", "6 weeks")
   - Price (decimal)
   - Image URL (optional)
4. Click "Create Course"
5. Course appears in grid

**Editing/Deleting:**
- Similar workflow to Services
- Toggle active/inactive status with button

**Search:**
- Real-time search by title or description

---

### 6. Expert Management

#### Purpose
Manage salon experts/staff members and their service associations.

#### Workflow Steps

**Adding an Expert:**
1. Navigate to Experts page (`/experts`)
2. Click "+ Add Expert"
3. Fill form:
   - Name (required)
   - Email (required)
   - Phone (optional)
   - Specialization (optional)
   - Bio (optional textarea)
   - Image URL (optional)
   - Associate Services (multi-select checkboxes)
4. Click "Create Expert"
5. Expert card appears in grid

**Managing Service Associations:**
- When editing, check/uncheck services
- Each expert can be associated with multiple services

**Search:**
- Filter experts by name or specialization

---

### 7. Support Ticket Management

#### Purpose
Handle customer inquiries and support tickets.

#### Workflow Steps
1. Navigate to Support page (`/support`)
2. View ticket list with:
   - Customer name, email, phone
   - Subject and message preview
   - Status badge (Open, In Progress, Resolved, Closed)
   - Priority badge (Low, Medium, High, Urgent)
   - Created date

**Filtering:**
- Filter by Status (dropdown)
- Filter by Priority (dropdown)
- Search by customer name or subject

**Responding to Tickets:**
1. Click on a ticket card
2. View full ticket details in modal
3. Add response in textarea
4. Update status (if resolving)
5. Click "Save Response" or "Mark as Resolved"
6. Ticket status updates immediately

---

### 8. Role-Based Access Control (RBAC) Management

#### Purpose
Configure user roles and permissions to control system access.

#### Workflow Steps

**Step 1: Configure Permissions (Permission Matrix)**
1. Navigate to Settings (`/settings`)
2. Click "Permission Matrix" card
3. View matrix table:
   - Rows: Roles (Admin, Manager, Sales - Owner/User hidden)
   - Columns: Permissions (users.view, services.manage, etc.)
   - Checkboxes: Enable/disable permissions per role
4. Check/uncheck permissions for each role
5. Click "Save Changes" for each role
6. Changes are applied immediately

**Step 2: Assign Roles to Users (Role Assignment)**
1. Navigate to Settings (`/settings`)
2. Click "Role Assignment" card
3. View available roles in grid cards
4. **Option A - Assign via Modal:**
   - Click "+ Assign Role by Email"
   - Enter email address(es) (comma-separated or newline-separated)
   - Select role from dropdown
   - Click "Assign Role"
   - Success message shows assigned count
5. **Option B - Quick Assign:**
   - Click "Assign This Role" on any role card
   - Modal opens with role pre-selected
   - Enter email(s) and submit

**Step 3: Create New Roles**
1. In Role Assignment page, click "+ Create Role"
2. Enter role name (e.g., "Manager", "Sales")
3. Select permissions from checklist
4. Click "Create Role"
5. New role appears in grid and permission matrix

**Important Notes:**
- Users must log out and log back in for role changes to take effect
- Frontend UI hides unauthorized features
- Backend API blocks unauthorized actions
- Owner and User roles are hidden from management UI

---

### 9. Appointments Management

#### Purpose
View and manage customer appointments.

#### Workflow Steps
1. Navigate to Appointments page (`/appointments`)
2. View appointment list with:
   - Customer name
   - Service name
   - Date and time
   - Status (Pending, Confirmed, Completed, Cancelled)
3. **Quick Book:** Click "Quick Book" in header for fast appointment creation
4. **Filter:** Filter by status or date range
5. **Update Status:** Change appointment status as needed

---

### 10. Reports & Analytics

#### Purpose
View business analytics and generate reports.

#### Workflow Steps
1. Navigate to Reports page (`/reports`)
2. View various analytics:
   - Revenue reports
   - Service performance
   - Customer analytics
   - Staff performance
3. Export data if needed

---

## Template Design

### Overall Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│                    HEADER (Fixed Top)                    │
│  [Quick Book]                    [User Avatar + Name]    │
│  Mobile Nav: [Dashboard] [Appointments] [Services]...  │
├──────────┬──────────────────────────────────────────────┤
│          │                                               │
│ SIDEBAR  │              MAIN CONTENT AREA                │
│ (Fixed)  │              (Scrollable)                     │
│          │                                               │
│ • Dashboard│                                             │
│ • Appointments│                                          │
│ • Services   │                                           │
│ • Customers  │                                           │
│ • Courses    │                                           │
│ • Experts    │                                           │
│ • Sales      │                                           │
│ • Support    │                                           │
│ • Reports    │                                           │
│ • Settings   │                                           │
│          │                                               │
│ [Logout] │                                               │
└──────────┴──────────────────────────────────────────────┘
```

---

### Component Hierarchy

```
App Layout
├── AuthGuard (Route Protection)
│   └── Main Container (flex min-h-screen bg-gray-50)
│       ├── Sidebar (Fixed Left, 256px width)
│       │   ├── Logo Section
│       │   ├── Navigation Menu (Permission-filtered)
│       │   └── Logout Button
│       └── Content Area (flex-1)
│           ├── Header (Fixed Top)
│           │   ├── Quick Book Button
│           │   └── User Profile Section
│           └── Main Content (Scrollable)
│               └── Page-Specific Content
```

---

### Design System

#### Color Palette
- **Primary Color:** `primary-500` (used for buttons, links, accents)
- **Background:** `gray-50` (main background)
- **Cards:** `white` with shadow
- **Text Primary:** `gray-800`
- **Text Secondary:** `gray-600`
- **Text Muted:** `gray-500`
- **Success:** Green shades
- **Error:** Red shades
- **Warning:** Yellow shades
- **Info:** Blue shades

#### Typography
- **Page Titles:** `text-2xl md:text-3xl font-bold text-gray-800`
- **Section Headers:** `text-xl font-semibold text-gray-800`
- **Body Text:** `text-sm text-gray-600`
- **Labels:** `text-sm font-medium text-gray-700`
- **Muted Text:** `text-xs text-gray-500`

#### Spacing System
- **Page Padding:** `p-4 sm:p-6`
- **Card Padding:** `p-6`
- **Section Gaps:** `gap-6` (grid), `mb-6` (vertical)
- **Button Padding:** `px-6 py-2`
- **Input Padding:** `px-4 py-2`

#### Border Radius
- **Cards:** `rounded-lg`
- **Buttons:** `rounded-lg`
- **Inputs:** `rounded-lg`
- **Badges:** `rounded` (small), `rounded-full` (pills)

#### Shadows
- **Cards:** `shadow` (default)
- **Hover:** `hover:shadow-lg`
- **Header:** `shadow-sm`

---

### Page Template Structure

#### Standard Page Layout

```tsx
<AuthGuard>
  <div className="flex min-h-screen bg-gray-50">
    <Sidebar />
    <div className="flex-1 flex flex-col overflow-hidden">
      <Header />
      <main className="flex-1 overflow-y-auto p-4 sm:p-6">
        <div className="max-w-7xl mx-auto">
          {/* Page Content */}
        </div>
      </main>
    </div>
  </div>
</AuthGuard>
```

#### Page Header Pattern

```tsx
<div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
  <div>
    <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Page Title</h1>
    <p className="text-gray-600 mt-2">Page description</p>
  </div>
  <div className="flex gap-4">
    {/* Search Input */}
    <input type="text" placeholder="Search..." />
    {/* Action Buttons */}
    <button className="px-6 py-2 bg-primary-500 text-white rounded-lg">
      + Add Item
    </button>
  </div>
</div>
```

---

### Component Patterns

#### 1. Card Grid Pattern

```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {items.map((item) => (
    <div key={item.id} className="bg-white rounded-lg shadow overflow-hidden">
      {/* Card Content */}
      <div className="p-6">
        <h3 className="text-xl font-semibold">{item.name}</h3>
        <p className="text-sm text-gray-600">{item.description}</p>
        <div className="flex space-x-2 mt-4">
          <button className="flex-1 px-4 py-2 bg-blue-500 text-white rounded">
            Edit
          </button>
          <button className="flex-1 px-4 py-2 bg-red-500 text-white rounded">
            Delete
          </button>
        </div>
      </div>
    </div>
  ))}
</div>
```

#### 2. Modal Pattern

```tsx
{showModal && (
  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
      <h2 className="text-2xl font-bold mb-4">Modal Title</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Form Fields */}
        <div className="flex gap-4 pt-4">
          <button type="submit" className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg">
            Submit
          </button>
          <button type="button" onClick={onClose} className="flex-1 px-6 py-2 bg-gray-300 rounded-lg">
            Cancel
          </button>
        </div>
      </form>
    </div>
  </div>
)}
```

#### 3. Form Input Pattern

```tsx
<div>
  <label className="block text-sm font-medium text-gray-700 mb-1">
    Field Label *
  </label>
  <input
    type="text"
    required
    value={formData.field}
    onChange={(e) => setFormData({ ...formData, field: e.target.value })}
    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
  />
</div>
```

#### 4. Stat Card Pattern

```tsx
<div className="bg-white rounded-lg shadow p-6">
  <div className="flex items-center justify-between">
    <div>
      <p className="text-sm text-gray-600">{title}</p>
      <p className="text-2xl font-bold text-gray-800">{value}</p>
    </div>
    <div className="text-right">
      <span className={`text-sm ${changeType === 'positive' ? 'text-green-600' : 'text-red-600'}`}>
        {change}%
      </span>
    </div>
  </div>
</div>
```

#### 5. Badge/Status Pattern

```tsx
<span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">
  Active
</span>

<span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded">
  Inactive
</span>

<span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
  System
</span>
```

---

### Responsive Design Breakpoints

- **Mobile:** `< 768px` (md breakpoint)
  - Sidebar hidden, mobile nav in header
  - Single column layouts
  - Stacked buttons
  - Reduced padding

- **Tablet:** `768px - 1024px` (md to lg)
  - Sidebar visible
  - 2-column grids
  - Standard spacing

- **Desktop:** `> 1024px` (lg+)
  - Full sidebar
  - 3-4 column grids
  - Maximum content width: `max-w-7xl`

---

### Interactive Elements

#### Buttons
- **Primary:** `bg-primary-500 text-white hover:bg-primary-600`
- **Secondary:** `bg-gray-300 text-gray-700 hover:bg-gray-400`
- **Danger:** `bg-red-500 text-white hover:bg-red-600`
- **Success:** `bg-green-500 text-white hover:bg-green-600`
- **Disabled:** `disabled:opacity-50`

#### Inputs
- **Standard:** `border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500`
- **Error State:** Add `border-red-500` class

#### Links
- **Navigation:** `hover:bg-primary-50 hover:text-primary-600`
- **Active:** `bg-primary-50 text-primary-600 border-r-4 border-primary-500`

---

### Loading States

```tsx
{loading ? (
  <div className="bg-white rounded-lg shadow p-8 text-center">
    <p className="text-gray-500">Loading...</p>
  </div>
) : (
  // Content
)}
```

### Empty States

```tsx
{items.length === 0 ? (
  <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
    No items found
  </div>
) : (
  // Content
)}
```

---

### Notification System

- **Library:** `react-hot-toast`
- **Success:** `toast.success('Message')`
- **Error:** `toast.error('Message')`
- **Info:** `toast('Message')`

---

### Permission-Based UI Rendering

```tsx
// Hide menu items
{menuItems.map((item) => {
  if (item.permission && !hasPermission(item.permission)) {
    return null;
  }
  return <MenuItem />;
})}

// Hide page sections
<PermissionGuard permission="services.manage">
  <button>Add Service</button>
</PermissionGuard>
```

---

### State Management Pattern

- **Library:** Zustand
- **Store:** `authStore.ts`
- **Pattern:**
  ```tsx
  const { user, login, logout, hasPermission } = useAuthStore();
  ```

---

### API Integration Pattern

```tsx
// API call with error handling
try {
  const res = await servicesAPI.createService(data);
  toast.success('Service created successfully');
  loadServices(); // Refresh list
} catch (error: any) {
  toast.error(error.response?.data?.message || 'Failed to create service');
}
```

---

### Key Design Principles

1. **Consistency:** All pages follow the same layout structure
2. **Responsiveness:** Mobile-first approach with breakpoint-based layouts
3. **Accessibility:** Semantic HTML, proper labels, keyboard navigation
4. **Performance:** Lazy loading, optimized images, efficient state updates
5. **User Experience:** Clear feedback (toasts), loading states, error handling
6. **Security:** Permission-based rendering, API-level authorization
7. **Maintainability:** Reusable components, consistent patterns, TypeScript types

---

## Summary

The admin panel follows a **consistent, permission-driven workflow** where:

1. **Authentication** determines initial access
2. **RBAC** controls what features are visible and accessible
3. **CRUD operations** are standardized across all entity pages
4. **Modal-based forms** provide consistent editing experience
5. **Grid layouts** display data in card format
6. **Search and filter** capabilities are available on list pages
7. **Real-time feedback** via toast notifications
8. **Responsive design** ensures usability across devices

The design system ensures **visual consistency** while the component patterns ensure **functional consistency** across all pages.
