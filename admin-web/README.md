# Salon Admin Web Application

Next.js admin panel for managing salon bookings, services, and customers.

## Features

- ✅ Admin authentication
- ✅ Dashboard with statistics
- ✅ Appointment management
- ✅ Service CRUD operations
- ✅ Customer management
- ✅ Expert management
- ✅ Real-time updates
- ✅ Responsive design

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **HTTP Client**: Axios
- **UI Components**: Headless UI
- **Notifications**: React Hot Toast

## Prerequisites

- Node.js 16+
- Backend API running on http://localhost:5000

## Installation

1. **Install dependencies**
```bash
cd admin-web
npm install
```

2. **Configure environment**
```bash
cp .env.local.example .env.local
# Edit .env.local with your API URL
```

3. **Run development server**
```bash
npm run dev
```

The admin panel will be available at http://localhost:3001

## Default Admin Credentials

Create an admin user in the database or use the backend API:

```sql
UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
```

## Project Structure

```
admin-web/
├── src/
│   ├── app/                    # Next.js app router pages
│   │   ├── dashboard/          # Dashboard page
│   │   ├── appointments/       # Appointments management
│   │   ├── services/           # Services management
│   │   ├── login/              # Login page
│   │   └── layout.tsx          # Root layout
│   ├── components/             # Reusable components
│   │   ├── AuthGuard.tsx       # Route protection
│   │   └── Sidebar.tsx         # Navigation sidebar
│   ├── lib/                    # Utilities
│   │   └── api.ts              # API client
│   └── store/                  # State management
│       └── authStore.ts        # Auth state
├── public/                     # Static assets
├── tailwind.config.js          # Tailwind configuration
├── next.config.js              # Next.js configuration
└── package.json                # Dependencies
```

## Available Pages

- `/login` - Admin login
- `/dashboard` - Main dashboard with statistics
- `/appointments` - View and manage appointments
- `/services` - CRUD operations for services
- `/customers` - Customer list and details
- `/experts` - Manage experts/stylists
- `/settings` - Admin settings

## Features Overview

### Dashboard
- Total appointments (confirmed, reserved, completed, cancelled)
- Revenue statistics (total and monthly)
- Today's appointments count
- Quick stats cards

### Appointments Management
- View all appointments with filters
- Update appointment status
- Mark as paid
- Confirm/Complete appointments
- Pagination support

### Services Management
- View all services in grid layout
- Create new services
- Edit existing services
- Delete services (soft delete)
- Service categories
- Price and duration management

## Build for Production

```bash
npm run build
npm start
```

## Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api/v1
NEXT_PUBLIC_APP_NAME=Salon Admin
```

## API Integration

The admin web communicates with the Node.js backend API. Ensure the backend is running before using the admin panel.

## Authentication Flow

1. Admin logs in with email and password
2. Backend validates credentials and returns JWT token
3. Token is stored in localStorage and Zustand store
4. All API requests include the token in Authorization header
5. AuthGuard protects admin routes from unauthorized access

## Styling

- Uses Tailwind CSS for styling
- Custom primary color (pink #FF6CBF) matching the mobile app
- Responsive design for all screen sizes
- Custom scrollbar styling

## Security

- JWT token-based authentication
- Role-based access control (admin/owner only)
- Protected routes with AuthGuard
- Automatic logout on token expiration
- Secure API communication

## License

MIT
