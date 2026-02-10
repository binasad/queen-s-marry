# Backend Setup Guide

## Prerequisites

### 1. PostgreSQL Installation (if not already installed)

**Windows:**
- Download from: https://www.postgresql.org/download/windows/
- During installation:
  - Remember the password you set for the `postgres` user
  - Choose port 5432 (default)
  - Add PostgreSQL to PATH (recommended during installation)

**Verification:**
```powershell
psql --version
```

### 2. Node.js and npm
- Already installed and working ✓

## Database Setup

### Step 1: Configure Environment Variables

Edit `.env` file in the backend directory and update:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=salon_db
DB_USER=postgres
DB_PASSWORD=your_postgres_password
```

### Step 2: Run Database Setup Script

```powershell
cd D:\Aztrosys\backend
npm run setup:db
```

This will:
1. Connect to PostgreSQL using the admin `postgres` user
2. Create the `salon_db` database (if it doesn't exist)
3. Create all required tables and extensions
4. Verify the setup was successful

### Step 3: Verify Database Creation

You can verify the database was created successfully by:

```powershell
psql -U postgres -d salon_db -c "\dt"
```

This will list all tables in the database.

## Running the Application

### Development Mode
```powershell
npm run dev
```

Server will start on `http://localhost:5000`

### Production Mode
```powershell
npm start
```

## Troubleshooting

### Error: `psql` not recognized
- PostgreSQL CLI is not in your system PATH
- **Solution**: Either:
  1. Add PostgreSQL to PATH (recommended)
  2. Use full path: `C:\Program Files\PostgreSQL\15\bin\psql` (adjust version)
  3. Install PostgreSQL from scratch and add to PATH

### Error: Connection refused
- PostgreSQL is not running
- **Solution**: 
  1. Start PostgreSQL service on Windows:
     ```powershell
     Start-Service postgresql-x64-15
     ```
  2. Or use pgAdmin to manage the service

### Error: Authentication failed (28P01)
- Incorrect password or username
- **Solution**:
  1. Check `DB_USER` and `DB_PASSWORD` in `.env`
  2. Verify credentials with: `psql -U postgres`

### Error: Database already exists
- Don't worry! The setup script is idempotent
- It will skip table creation if they already exist

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── modules/         # Feature modules (auth, users, services, appointments)
│   ├── middlewares/     # Authentication & authorization
│   ├── utils/           # Helper utilities
│   ├── scripts/         # Setup and maintenance scripts
│   ├── app.js           # Express app configuration
│   └── server.js        # Server entry point
├── database/
│   └── schema.sql       # Database schema
├── .env                 # Environment configuration
└── package.json         # Dependencies and scripts
```

## API Endpoints

Base URL: `http://localhost:5000/api/v1`

### Auth
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `GET /auth/verify-email/:token` - Verify email
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password

### Users
- `GET /profile` - Get current user profile
- `PUT /profile` - Update profile
- `GET /users` - Get all users (Admin)
- `GET /users/:id` - Get user by ID (Admin)
- `DELETE /users/:id` - Delete user (Admin)

### Services
- `GET /categories` - Get service categories
- `GET /services` - Get all services
- `GET /services/:id` - Get service by ID
- `POST /services` - Create service (Admin)
- `PUT /services/:id` - Update service (Admin)
- `DELETE /services/:id` - Delete service (Admin)
- `GET /experts` - Get experts

### Appointments
- `POST /appointments` - Create appointment
- `GET /appointments/my` - Get user appointments
- `DELETE /appointments/:id/cancel` - Cancel appointment
- `GET /appointments` - Get all appointments (Admin)
- `PUT /appointments/:id/status` - Update appointment status (Admin)
- `PUT /appointments/:id/pay` - Mark appointment as paid (Admin)
- `GET /dashboard/stats` - Get dashboard statistics (Admin)

## Security Notes

1. **JWT Secrets**: Change `JWT_SECRET` and `JWT_REFRESH_SECRET` in `.env` for production
2. **Email Configuration**: Set up real email credentials for production
3. **Rate Limiting**: Configured to 100 requests per 15 minutes per IP
4. **CORS**: Currently allows all origins. Configure for production.

## Additional Commands

- `npm audit` - Check for security vulnerabilities
- `npm audit fix` - Fix vulnerabilities
- `npm test` - Run tests (if configured)
- `npm run lint` - Lint code
- `npm run lint:fix` - Fix linting issues
