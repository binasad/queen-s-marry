# Salon App Backend API Reference

## Base URL
```
http://localhost:5000/api/v1
```

## Auth APIs

### 1. Register
```
POST /auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "Test123!",
  "phone": "+11234567890",
  "address": "123 Main St",
  "gender": "Male"
}

Response (201):
{
  "success": true,
  "message": "Registration successful! Please check your email to verify your account.",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": {
        "id": "uuid",
        "name": "User",
        "permissions": ["appointments.create"]
      }
    }
  }
}
```

### 2. Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "Test123!"
}

Response (200):
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": {
        "id": "uuid",
        "name": "User",
        "permissions": ["appointments.create"]
      },
      "profileImage": null
    },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

### 3. Verify Email
```
GET /auth/verify-email/:token

Example:
GET /auth/verify-email/abc123def456...

Response (200):
{
  "success": true,
  "message": "Email verified successfully! You can now login.",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

### 4. Resend Verification Email
```
POST /auth/resend-verification
Content-Type: application/json

{
  "email": "john@example.com"
}

Response (200):
{
  "success": true,
  "message": "Verification email sent successfully."
}
```

### 5. Forgot Password
```
POST /auth/forgot-password
Content-Type: application/json

{
  "email": "john@example.com"
}

Response (200):
{
  "success": true,
  "message": "If an account exists with this email, a password reset link has been sent."
}
```

### 6. Reset Password
```
POST /auth/reset-password
Content-Type: application/json

{
  "token": "reset-token-from-email",
  "newPassword": "NewTest123!"
}

Response (200):
{
  "success": true,
  "message": "Password reset successful. You can now login with your new password."
}
```

### 7. Refresh Token
```
POST /auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "eyJhbGc..."
}

Response (200):
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": {
        "id": "uuid",
        "name": "User",
        "permissions": ["appointments.create"]
      },
      "profileImage": null
    },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

### 8. Change Password (Auth Required)
```
POST /auth/change-password
Content-Type: application/json
Authorization: Bearer <accessToken>

{
  "currentPassword": "Test123!",
  "newPassword": "NewTest123!"
}

Response (200):
{
  "success": true,
  "message": "Password changed successfully."
}
```

---

## User APIs

### 1. Get Current User Profile (Auth Required)
```
GET /users/profile
Authorization: Bearer <accessToken>

Response (200):
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+11234567890",
    "address": "123 Main St",
    "gender": "Male",
    "profileImage": null,
    "role": {
      "id": "uuid",
      "name": "User",
      "permissions": ["appointments.create"]
    }
  }
}
```

### 2. Get User by ID (Auth Required)
```
GET /users/:userId
Authorization: Bearer <accessToken>

Response (200):
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+11234567890",
    "address": "123 Main St",
    "gender": "Male",
    "role": {
      "id": "uuid",
      "name": "User"
    }
  }
}
```

### 3. List All Users (Admin Only)
```
GET /users
Authorization: Bearer <adminAccessToken>

Query params:
?page=1&limit=10&search=john

Response (200):
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": {
        "id": "uuid",
        "name": "User"
      }
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "limit": 10,
    "pages": 5
  }
}
```

---

## Service APIs

### 1. List All Services
```
GET /services
Optional query params: ?category=uuid&active=true

Response (200):
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Haircut",
      "description": "Professional haircut",
      "price": 25.00,
      "duration": 30,
      "category_id": "uuid",
      "image_url": "https://...",
      "is_active": true
    }
  ]
}
```

### 2. Get Service by ID
```
GET /services/:serviceId

Response (200):
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Haircut",
    "description": "Professional haircut",
    "price": 25.00,
    "duration": 30,
    "image_url": "https://...",
    "is_active": true
  }
}
```

### 3. Create Service (Admin Only)
```
POST /services
Content-Type: application/json
Authorization: Bearer <adminAccessToken>

{
  "category_id": "uuid",
  "name": "Haircut",
  "description": "Professional haircut",
  "price": 25.00,
  "duration": 30,
  "image_url": "https://...",
  "tags": ["hair", "cut", "style"],
  "is_active": true
}

Response (201):
{
  "success": true,
  "message": "Service created successfully",
  "data": {
    "id": "uuid",
    "name": "Haircut",
    ...
  }
}
```

### 4. Update Service (Admin Only)
```
PUT /services/:serviceId
Content-Type: application/json
Authorization: Bearer <adminAccessToken>

{
  "name": "Haircut Premium",
  "price": 35.00,
  "duration": 45,
  "is_active": true
}

Response (200):
{
  "success": true,
  "message": "Service updated successfully",
  "data": { ... }
}
```

### 5. Delete Service (Admin Only)
```
DELETE /services/:serviceId
Authorization: Bearer <adminAccessToken>

Response (200):
{
  "success": true,
  "message": "Service deleted successfully"
}
```

---

## Appointment APIs

### 1. Get All Appointments (Auth Required)
```
GET /appointments
Authorization: Bearer <accessToken>

Query params: ?status=confirmed&date=2026-01-25&limit=10&page=1

Response (200):
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "customer_name": "Alice",
      "customer_email": "alice@example.com",
      "customer_phone": "+11234567890",
      "service_id": "uuid",
      "expert_id": "uuid",
      "appointment_date": "2026-01-25",
      "appointment_time": "14:00",
      "status": "confirmed",
      "total_price": 25.00,
      "payment_status": "paid"
    }
  ]
}
```

### 2. Get Appointment by ID (Auth Required)
```
GET /appointments/:appointmentId
Authorization: Bearer <accessToken>

Response (200):
{
  "success": true,
  "data": {
    "id": "uuid",
    "customer_name": "Alice",
    ...
  }
}
```

### 3. Create Appointment (User)
```
POST /appointments
Content-Type: application/json
Authorization: Bearer <accessToken>

{
  "service_id": "uuid",
  "expert_id": "uuid",
  "customer_name": "Alice",
  "customer_email": "alice@example.com",
  "customer_phone": "+11234567890",
  "appointment_date": "2026-01-25",
  "appointment_time": "14:00",
  "notes": "Please be on time"
}

Response (201):
{
  "success": true,
  "message": "Appointment created successfully",
  "data": { ... }
}
```

### 4. Update Appointment (Admin Only)
```
PUT /appointments/:appointmentId
Content-Type: application/json
Authorization: Bearer <adminAccessToken>

{
  "status": "confirmed",
  "payment_status": "paid",
  "payment_method": "card"
}

Response (200):
{
  "success": true,
  "message": "Appointment updated successfully",
  "data": { ... }
}
```

### 5. Delete/Cancel Appointment (User or Admin)
```
DELETE /appointments/:appointmentId
Content-Type: application/json
Authorization: Bearer <accessToken>

{
  "cancelled_reason": "Emergency came up"
}

Response (200):
{
  "success": true,
  "message": "Appointment cancelled successfully"
}
```

---

## Role APIs

### 1. Get All Roles (Auth Required)
```
GET /roles
Authorization: Bearer <accessToken>

Response (200):
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Owner",
      "is_system_role": true,
      "permissions": [
        { "id": "uuid", "slug": "users.manage", "description": "Manage all users" },
        { "id": "uuid", "slug": "services.manage", "description": "Manage services" },
        ...
      ]
    },
    {
      "id": "uuid",
      "name": "Admin",
      "is_system_role": true,
      "permissions": [...]
    },
    {
      "id": "uuid",
      "name": "User",
      "is_system_role": true,
      "permissions": [
        { "id": "uuid", "slug": "appointments.create", "description": "Book appointments" }
      ]
    }
  ]
}
```

### 2. Get Role by ID (Auth Required)
```
GET /roles/:roleId
Authorization: Bearer <accessToken>

Response (200):
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Admin",
    "permissions": [...]
  }
}
```

### 3. Create Role (Admin Only)
```
POST /roles
Content-Type: application/json
Authorization: Bearer <adminAccessToken>

{
  "name": "Receptionist",
  "permission_ids": [
    "uuid-of-appointments.manage_all",
    "uuid-of-users.view"
  ]
}

Response (201):
{
  "success": true,
  "message": "Role created successfully",
  "data": { ... }
}
```

### 4. Update Role (Admin Only)
```
PUT /roles/:roleId
Content-Type: application/json
Authorization: Bearer <adminAccessToken>

{
  "name": "Senior Receptionist",
  "permission_ids": [
    "uuid-of-appointments.manage_all",
    "uuid-of-users.view",
    "uuid-of-services.manage"
  ]
}

Response (200):
{
  "success": true,
  "message": "Role updated successfully",
  "data": { ... }
}
```

### 5. Delete Role (Admin Only, not system roles)
```
DELETE /roles/:roleId
Authorization: Bearer <adminAccessToken>

Response (200):
{
  "success": true,
  "message": "Role deleted successfully"
}
```

---

## Test Workflow

1. **Register** → POST /auth/register
2. **Verify Email** → GET /auth/verify-email/:token (from Ethereal)
3. **Login** → POST /auth/login (get accessToken)
4. **Get Profile** → GET /users/profile (with accessToken)
5. **List Services** → GET /services
6. **Create Appointment** → POST /appointments (with accessToken)
7. **List Appointments** → GET /appointments (with accessToken)

---

## Notes
- All protected routes require `Authorization: Bearer <accessToken>` header
- Admin routes require user to have Admin/Owner role with appropriate permissions
- Email will be sent to Ethereal inbox for verification/reset links
- All timestamps are in UTC
- Passwords must be 8+ chars with uppercase, number, and special character
