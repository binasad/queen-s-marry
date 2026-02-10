# 💇 Salon Management System - Full Stack Application

## 🎯 Project Overview

A comprehensive salon management system with mobile app (Flutter), admin web portal (Next.js), and RESTful API backend (Node.js). Features real-time appointment booking, role-based access control, email verification with OTP, and scalable architecture.

**Live Demo**: [Link to deployed app]  
**API Documentation**: [Link to API docs]  
**Architecture Diagrams**: See [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 🏗️ Architecture & Technology Stack

### **Backend (Node.js + Express)**
- **Runtime**: Node.js 18+
- **Framework**: Express.js with modular architecture
- **Database**: PostgreSQL 16 with advanced features
- **Authentication**: JWT with refresh tokens
- **Security**: Helmet, rate limiting, CORS, input validation
- **Email**: Nodemailer with OTP verification
- **Environment**: Dotenv for configuration

### **Frontend - Mobile App (Flutter)**
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **HTTP Client**: Dio with interceptors
- **Storage**: Flutter Secure Storage
- **UI**: Material Design with custom themes

### **Frontend - Admin Web (Next.js)**
- **Framework**: Next.js 14 with App Router
- **Styling**: Tailwind CSS
- **State Management**: React Context
- **API Integration**: Axios

### **Database Schema**
- **PostgreSQL** with UUID primary keys
- **RBAC System**: Dynamic roles and permissions
- **Audit Trail**: Timestamps on all tables
- **Indexes**: Optimized for query performance
- **Constraints**: Foreign keys, check constraints

---

## 🚀 Key Features

### **Authentication & Authorization**
- ✅ Email/password registration with 6-digit OTP verification
- ✅ JWT access + refresh token system (7-day access, 30-day refresh)
- ✅ Password reset with email OTP
- ✅ Account lockout after 3 failed attempts (30-second cooldown)
- ✅ Role-based access control (Admin, Owner, User)
- ✅ Email verification required before login

### **Appointment Management**
- Book appointments with date/time selection
- Service selection with pricing
- Real-time availability checking
- Status tracking (Pending, Confirmed, Completed, Cancelled)
- Payment integration ready

### **User Management**
- User profiles with CRUD operations
- Role assignment and permissions
- Profile image upload
- Activity tracking

### **Service Management**
- Service categories
- Service pricing and duration
- Sub-services (add-ons)
- Service gallery

### **Security Features**
- Password hashing with bcrypt (10 rounds)
- SQL injection prevention (parameterized queries)
- XSS protection
- CSRF tokens ready
- Rate limiting (100 requests per 15 minutes)
- Secure headers with Helmet.js

---

## 📊 System Architecture

```
┌─────────────────┐         ┌─────────────────┐         ┌──────────────────┐
│  Flutter App    │────────▶│   Node.js API   │────────▶│   PostgreSQL     │
│  (Mobile)       │◀────────│   (Express)     │◀────────│   Database       │
└─────────────────┘         └─────────────────┘         └──────────────────┘
                                     │
                                     │
                            ┌────────▼─────────┐
                            │  Email Service   │
                            │  (Nodemailer)    │
                            └──────────────────┘

                            Future Integrations:
                            ├── AWS S3 (Images)
                            ├── Redis (Caching)
                            └── FCM (Push Notifications)
```

---

## 🗄️ Database Design

### **Core Tables**
- `users` - User accounts with role-based access
- `roles` - Dynamic role definitions
- `permissions` - Granular permission system
- `role_permissions` - Many-to-many mapping
- `pending_registrations` - OTP verification queue
- `appointments` - Booking system
- `services` - Service catalog
- `service_categories` - Service organization
- `experts` - Staff management
- `notifications` - In-app notifications

### **Key Indexes**
```sql
-- User lookups
CREATE INDEX idx_users_email ON users(email);

-- Appointment queries
CREATE INDEX idx_appointments_user ON appointments(user_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);

-- OTP verification
CREATE INDEX idx_pending_code ON pending_registrations(verification_code);
```

---

## 🔧 API Endpoints

### **Authentication**
```
POST   /api/v1/auth/register          - User registration with OTP
POST   /api/v1/auth/verify-email      - Verify email with 6-digit code
POST   /api/v1/auth/login             - Login with email/password
POST   /api/v1/auth/refresh-token     - Refresh access token
POST   /api/v1/auth/forgot-password   - Request password reset
POST   /api/v1/auth/reset-password    - Reset password with token
POST   /api/v1/auth/change-password   - Change password (authenticated)
POST   /api/v1/auth/resend-verification - Resend OTP code
```

### **Users**
```
GET    /api/v1/users/profile          - Get current user profile
PUT    /api/v1/users/profile          - Update user profile
GET    /api/v1/users                  - List users (admin only)
GET    /api/v1/users/:id              - Get user by ID (admin only)
DELETE /api/v1/users/:id              - Delete user (admin only)
```

### **Appointments**
```
GET    /api/v1/appointments           - List appointments
POST   /api/v1/appointments           - Create appointment
GET    /api/v1/appointments/:id       - Get appointment details
PUT    /api/v1/appointments/:id       - Update appointment
DELETE /api/v1/appointments/:id       - Cancel appointment
```

### **Services**
```
GET    /api/v1/services               - List all services
GET    /api/v1/services/:id           - Get service details
POST   /api/v1/services               - Create service (admin)
PUT    /api/v1/services/:id           - Update service (admin)
DELETE /api/v1/services/:id           - Delete service (admin)
```

---

## 📈 Performance Optimizations

### **Database**
- Connection pooling (max 20 connections)
- Prepared statements for all queries
- Indexed foreign keys
- Query result caching ready

### **API**
- Response compression with gzip
- Rate limiting to prevent abuse
- Async/await for non-blocking operations
- Error handling middleware

### **Security**
- Password validation regex (8+ chars, upper, lower, number, special)
- Email verification required
- JWT token expiry management
- Failed login attempt tracking

---

## 🛠️ Setup & Installation

### **Prerequisites**
- Node.js 18+
- PostgreSQL 16+
- Flutter 3.x+
- npm/yarn

### **Backend Setup**
```bash
cd backend
npm install
cp .env.example .env  # Configure environment variables
npm run db:migrate    # Run database migrations
npm run dev          # Start development server
```

### **Flutter App Setup**
```bash
cd salon-app
flutter pub get
flutter run
```

### **Admin Web Setup**
```bash
cd admin-web
npm install
npm run dev
```

---

## 🧪 Testing & Quality

### **Implemented**
- Input validation with express-validator
- Error handling middleware
- SQL injection prevention
- XSS protection

### **Ready to Add**
- Unit tests (Jest)
- Integration tests (Supertest)
- Load testing (Artillery)
- Code coverage reports

---

## 🚀 Deployment Strategy

### **Planned Architecture**
```
AWS EC2/Elastic Beanstalk  → Node.js API
AWS RDS                     → PostgreSQL Database
AWS S3                      → Static files & images
AWS CloudFront              → CDN for faster delivery
AWS SES                     → Email service
GitHub Actions              → CI/CD pipeline
```

---

## 📊 Metrics & Monitoring

### **To Implement**
- Request logging with Morgan
- Error tracking (Sentry)
- Performance monitoring (New Relic/DataDog)
- Database query analysis
- API response time tracking

---

## 🔐 Security Checklist

- ✅ Password hashing with bcrypt
- ✅ JWT authentication
- ✅ Rate limiting
- ✅ CORS configuration
- ✅ Helmet.js security headers
- ✅ Input validation
- ✅ SQL injection prevention
- ✅ Email verification
- ✅ Account lockout mechanism
- ⏳ HTTPS enforcement (deployment)
- ⏳ WAF configuration (deployment)

---

## 📝 Code Quality

### **Standards**
- ESLint configuration
- Prettier for code formatting
- Modular architecture
- Clear separation of concerns
- RESTful API design
- Consistent error responses

### **Documentation**
- API documentation with Swagger (ready to add)
- Code comments
- Database schema documentation
- Architecture diagrams

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

### **Backend Development**
- RESTful API design
- Database design & optimization
- Authentication & authorization
- Security best practices
- Error handling
- Async programming

### **PostgreSQL**
- Complex schema design
- Query optimization
- Indexing strategies
- Foreign key relationships
- Transaction management

### **AWS (Ready for deployment)**
- EC2/Elastic Beanstalk
- RDS configuration
- S3 storage
- CloudWatch monitoring
- IAM policies

---

## 🔄 Future Enhancements

- [ ] Redis caching layer
- [ ] WebSocket for real-time features
- [ ] Background job processing (Bull)
- [ ] Image upload to AWS S3
- [ ] SMS notifications (Twilio)
- [ ] Push notifications (FCM)
- [ ] Advanced analytics dashboard
- [ ] Payment gateway integration
- [ ] Multi-language support
- [ ] Docker containerization
- [ ] Kubernetes orchestration

---

## 📞 Contact

**Developer**: [Your Name]  
**Email**: [Your Email]  
**LinkedIn**: [Your LinkedIn]  
**GitHub**: [Your GitHub]  
**Portfolio**: [Your Portfolio Site]

---

## 📄 License

MIT License - see LICENSE file for details

---

**⭐ Star this repository if you find it useful!**
