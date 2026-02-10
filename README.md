# Salon Booking System - Complete Project

A comprehensive salon booking system with a Flutter mobile app (user-only), Node.js backend, PostgreSQL database, and Next.js admin web panel.

## Project Structure

```
Aztrosys/
├── salon-app/          # Flutter mobile app (user interface)
├── backend/            # Node.js REST API
├── admin-web/          # Next.js admin dashboard
└── README.md           # This file
```

## Architecture Overview

### Mobile App (salon-app) - User Only
- Flutter-based mobile application
- **Users can**: Book appointments, view services, manage profile
- **NO admin features** in mobile app
- Authentication with email verification
- Service browsing and booking
- Appointment management
- Push notifications

### Backend (Node.js + PostgreSQL)
- RESTful API built with Express.js
- PostgreSQL database for data persistence
- JWT-based authentication
- Email notifications (verification, password reset, bookings)
- 4-hour payment window for appointments
- Role-based access control (user/admin/owner)

### Admin Web (Next.js)
- Web-based admin dashboard
- **Admin/Owner only** - complete management interface
- Dashboard with statistics
- Appointment management (view, confirm, complete, cancel)
- Service CRUD operations
- Customer management
- Expert management
- Revenue tracking

## Key Features

### User Features (Mobile App)
✅ User registration and authentication
✅ Email verification required
✅ Browse services by category
✅ Book appointments with date/time selection
✅ Choose pay now or pay later (4-hour window)
✅ View appointment history
✅ Expert/stylist selection
✅ Profile management
✅ Notifications

### Admin Features (Web Dashboard)
✅ Complete appointment management
✅ Service CRUD (Create, Read, Update, Delete)
✅ Mark payments as received
✅ Update appointment status
✅ Dashboard with statistics
✅ Customer list and details
✅ Expert management
✅ Revenue reports

## Technology Stack

### Mobile (User)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider/ChangeNotifier
- **Backend**: Migrated from Firebase to Node.js REST API

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Tokens)
- **Email**: Nodemailer
- **Security**: bcrypt, helmet, rate limiting

### Admin Web
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State**: Zustand
- **HTTP**: Axios

## Database Schema

### Main Tables
- **users** - User accounts (role: user/admin/owner)
- **service_categories** - Service categories
- **services** - Salon services with pricing
- **experts** - Stylists/beauticians
- **appointments** - Bookings with status tracking
- **reviews** - Customer reviews
- **offers** - Promotional offers
- **notifications** - User notifications

## Getting Started

### Prerequisites
- Node.js 16+
- PostgreSQL 13+
- Flutter 3.x
- npm or yarn

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create database
createdb salon_db

# Run schema
psql -d salon_db -f database/schema.sql

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start server
npm run dev
```

Backend runs on: http://localhost:5000

### Admin Web Setup

```bash
cd admin-web

# Install dependencies
npm install

# Configure environment
cp .env.local.example .env.local

# Start development server
npm run dev
```

Admin web runs on: http://localhost:3001

### Mobile App Setup

```bash
cd salon-app

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

**Note**: Update the API base URL in the mobile app to point to your backend:
- Update API configuration to use `http://YOUR_BACKEND_IP:5000/api/v1`

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/verify-email/:token` - Email verification
- `POST /api/v1/auth/forgot-password` - Password reset request
- `POST /api/v1/auth/reset-password` - Reset password
- `GET /api/v1/auth/profile` - Get user profile (protected)

### Services
- `GET /api/v1/categories` - Get all categories
- `GET /api/v1/services` - Get all services
- `GET /api/v1/services/:id` - Get service by ID
- `POST /api/v1/services` - Create service (admin only)
- `PUT /api/v1/services/:id` - Update service (admin only)
- `DELETE /api/v1/services/:id` - Delete service (admin only)

### Appointments
- `POST /api/v1/appointments` - Create appointment
- `GET /api/v1/appointments/my` - Get user appointments
- `GET /api/v1/appointments` - Get all appointments (admin)
- `PUT /api/v1/appointments/:id/status` - Update status (admin)
- `PUT /api/v1/appointments/:id/pay` - Mark as paid (admin)
- `DELETE /api/v1/appointments/:id/cancel` - Cancel appointment

### Dashboard
- `GET /api/v1/dashboard/stats` - Get statistics (admin)

## Security Features

✅ Password hashing with bcrypt
✅ JWT authentication
✅ Email verification required
✅ Rate limiting (100 req/15min)
✅ Brute force protection (3 attempts = 30s lockout)
✅ Role-based access control
✅ Generic error messages (prevents email enumeration)
✅ Secure password requirements

## Deployment

### Backend Deployment
1. Set up PostgreSQL database
2. Configure environment variables
3. Run database migrations
4. Deploy to your server (PM2, Docker, etc.)
5. Set up SSL/TLS
6. Configure email service

### Admin Web Deployment
1. Build the Next.js app: `npm run build`
2. Deploy to Vercel, Netlify, or your server
3. Set environment variables
4. Configure domain and SSL

### Mobile App Deployment
1. Update API URLs to production
2. Build release APK/IPA
3. Upload to Google Play Store / Apple App Store
4. Configure push notifications (FCM)

## Default Roles

- **user**: Regular customers (mobile app only)
- **admin**: Admin staff (web dashboard)
- **owner**: Business owner (web dashboard, full access)

To promote a user to admin:
```sql
UPDATE users SET role = 'admin' WHERE email = 'admin@salon.com';
```

## Business Logic

### Appointment Flow
1. User books appointment (mobile app)
2. Chooses "Pay Now" or "Pay Later"
3. If "Pay Now" → Status: confirmed, Payment: paid
4. If "Pay Later" → Status: reserved, Expires in 4 hours
5. Admin can mark as paid when customer arrives
6. Admin can confirm, complete, or cancel appointments

### Payment Window
- Reservations expire after 4 hours if not paid
- Reminder email sent 3 hours after booking
- Auto-cancellation on expiration (cron job needed)

## Future Enhancements

- [ ] Push notifications (FCM)
- [ ] Online payment integration (Stripe/Razorpay)
- [ ] SMS notifications
- [ ] Reviews and ratings system
- [ ] Loyalty program
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Calendar integration
- [ ] Cron jobs for expired appointments
- [ ] File upload for service images

## License

MIT

## Support

For issues and questions, please create an issue in the repository.

---

**Important Notes:**
1. Mobile app is **USER ONLY** - no admin features
2. Admin dashboard is **WEB ONLY** - for admin/owner management
3. Backend API serves both mobile and web clients
4. Email verification is required for all users
5. Appointments have a 4-hour payment window if "Pay Later" is selected
