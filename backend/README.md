# Salon Booking System - Backend API

A comprehensive Node.js REST API for a salon booking application with PostgreSQL database.

## Features

- ✅ User authentication (register, login, email verification, password reset)
- ✅ Service management with categories
- ✅ Appointment booking system
- ✅ Expert/stylist management
- ✅ 4-hour payment window for reservations
- ✅ Admin dashboard with statistics
- ✅ Email notifications
- ✅ Rate limiting and security features

## Tech Stack

- **Backend**: Node.js with Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Tokens)
- **Email**: Nodemailer
- **Security**: Helmet, bcrypt, rate limiting

## Prerequisites

- Node.js (v16 or higher)
- PostgreSQL (v13 or higher)
- npm or yarn

## Installation

1. **Clone the repository**
```bash
cd backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Set up PostgreSQL database**
```bash
# Create database
createdb salon_db

# Run schema
psql -d salon_db -f database/schema.sql
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. **Start the server**
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication (`/api/v1/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/register` | Register new user | No |
| POST | `/login` | Login user | No |
| GET | `/verify-email/:token` | Verify email | No |
| POST | `/resend-verification` | Resend verification email | No |
| POST | `/forgot-password` | Request password reset | No |
| POST | `/reset-password` | Reset password | No |
| GET | `/profile` | Get user profile | Yes |
| PUT | `/profile` | Update profile | Yes |
| POST | `/change-password` | Change password | Yes |

### Services (`/api/v1`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/categories` | Get all categories | No |
| GET | `/services` | Get all services | No |
| GET | `/services/:id` | Get service by ID | No |
| GET | `/experts` | Get all experts | No |
| POST | `/services` | Create service | Admin |
| PUT | `/services/:id` | Update service | Admin |
| DELETE | `/services/:id` | Delete service | Admin |

### Appointments (`/api/v1`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/appointments` | Create appointment | Yes |
| GET | `/appointments/my` | Get user appointments | Yes |
| DELETE | `/appointments/:id/cancel` | Cancel appointment | Yes |
| GET | `/appointments` | Get all appointments | Admin |
| PUT | `/appointments/:id/status` | Update status | Admin |
| PUT | `/appointments/:id/pay` | Mark as paid | Admin |
| GET | `/dashboard/stats` | Get statistics | Admin |

## Database Schema

### Main Tables

- **users** - User accounts and profiles
- **service_categories** - Service categories (Hair, Makeup, etc.)
- **services** - Available salon services
- **experts** - Stylists/beauticians
- **appointments** - Customer bookings
- **reviews** - Service reviews
- **offers** - Promotional offers
- **notifications** - User notifications

## Security Features

- Password hashing with bcrypt
- JWT-based authentication
- Rate limiting (100 requests per 15 minutes)
- Email verification required
- Brute force protection (3 failed attempts = 30s lockout)
- Generic error messages (prevents email enumeration)
- Helmet.js for security headers
- CORS protection

## Payment System

- **Pay Now**: Instant confirmation
- **Pay Later**: 4-hour reservation window
- Auto-cancellation after expiration
- Payment reminder emails

## Email Templates

- Email verification
- Password reset
- Appointment confirmation
- Appointment reminder

## Environment Variables

See `.env.example` for all required configuration variables.

## Development

```bash
# Run in development mode with auto-reload
npm run dev

# Run tests
npm test

# Run database migrations
npm run migrate
```

## Production Deployment

1. Set `NODE_ENV=production`
2. Configure production database
3. Set up SSL/TLS
4. Configure email service
5. Set strong JWT secrets
6. Enable rate limiting
7. Set up monitoring and logging

## API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": []
}
```

## License

MIT
