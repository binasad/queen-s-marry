<div align="center">

# ✨ Merry Queen — Salon Booking System

**A full-stack salon management platform built for real-world production use**

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![AWS](https://img.shields.io/badge/AWS_EC2-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Google Play](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)

<br/>

**Mobile App** · **Admin Dashboard** · **REST API** · **Automated CI/CD to Google Play**

<br/>

[📖 Technical Decisions](docs/TECHNICAL_DECISIONS.md) &nbsp;·&nbsp; [🚀 CI/CD Blog](CICD_GOOGLE_PLAY_BLOG.md) &nbsp;·&nbsp; [📐 Architecture](ARCHITECTURE.md)

</div>

---

## 🏗️ Architecture

```
                    ┌──────────────────────────────────────────────────────┐
                    │                   Merry Queen Platform               │
                    └──────────────────────────────────────────────────────┘

   ┌─────────────────┐       ┌───────────────────┐       ┌─────────────────┐
   │  📱 Flutter App │       │  🌐 Admin Panel   │       │  🤖 CI/CD       │
   │  (Android)      │       │  (Next.js 14)     │       │  GitHub Actions │
   │                 │       │                   │       │                 │
   │  • Book appts   │       │  • Dashboard      │       │  • Build APK    │
   │  • Browse svcs  │       │  • Manage staff   │       │  • Build AAB    │
   │  • Payments     │       │  • Revenue stats  │       │  • Sign release │
   │  • Notifications│       │  • CRUD services  │       │  • Publish to   │
   │                 │       │                   │       │    Google Play  │
   └────────┬────────┘       └────────┬──────────┘       └─────────────────┘
            │                         │
            └────────────┬────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  ⚙️ Node.js REST API │
              │  Express.js + JWT    │
              │  Docker on AWS EC2   │
              └──────────┬───────────┘
                         │
              ┌──────────┴───────────┐
              │  🗄️ PostgreSQL       │
              │  UUID PKs · RBAC     │
              │  Indexed queries     │
              └──────────────────────┘
```

---

## 📁 Project Structure

```
Aztrosys/
├── salon-app/              # 📱 Flutter mobile app (user-facing)
├── backend/                # ⚙️ Node.js REST API + PostgreSQL
├── admin-web/              # 🌐 Next.js admin dashboard
├── terraform/              # ☁️ AWS infrastructure as code
├── .github/workflows/      # 🤖 CI/CD pipelines
│   ├── salon-app.yaml      #    → Flutter → Google Play
│   ├── backend.yaml        #    → Docker → EC2
│   └── admin-web.yaml      #    → Vercel
└── docs/                   # 📖 Technical documentation
```

---

## ⚡ Tech Stack

### 📱 Mobile App

| Layer | Technology |
|:------|:-----------|
| Framework | **Flutter 3.x** |
| Language | **Dart** |
| State Management | **Provider** |
| HTTP Client | **Dio + Interceptors** |
| Auth | **JWT + Secure Storage** |
| Notifications | **Firebase FCM** |

### ⚙️ Backend API

| Layer | Technology |
|:------|:-----------|
| Runtime | **Node.js 18** |
| Framework | **Express.js** |
| Database | **PostgreSQL 16** |
| Auth | **JWT (access + refresh)** |
| Email | **Nodemailer + OTP** |
| Deployment | **Docker on EC2** |

### 🌐 Admin Panel

| Layer | Technology |
|:------|:-----------|
| Framework | **Next.js 14** |
| Language | **TypeScript** |
| Styling | **Tailwind CSS** |
| State Management | **Zustand** |
| HTTP Client | **Axios** |
| Deployment | **Vercel** |

**Production admin dashboard**: [queen-s-marry.vercel.app](https://queen-s-marry.vercel.app/)

---

## ✅ Features

### 📱 User App (Mobile)

- ✅ Email registration with OTP verification
- ✅ Browse services by category
- ✅ Book appointments with date/time slots
- ✅ Choose expert/stylist
- ✅ Pay now or pay later (4-hour window)
- ✅ Appointment history & status tracking
- ✅ Push notifications
- ✅ Profile management

### 🌐 Admin Dashboard (Web)

- ✅ Real-time statistics dashboard
- ✅ Appointment management (confirm/complete/cancel)
- ✅ Service CRUD operations
- ✅ Customer & expert management
- ✅ Revenue reports & tracking
- ✅ Mark payments as received
- ✅ Role-based access (Admin / Owner)

---

## 🔐 Security

| Feature | Implementation |
|:--------|:---------------|
| Password Hashing | bcrypt (10 rounds) |
| Authentication | JWT access + refresh tokens |
| Email Verification | 6-digit OTP required before login |
| Rate Limiting | 100 requests / 15 minutes |
| Brute Force Protection | 3 failed attempts → 30s lockout |
| RBAC | Dynamic roles: `user` · `admin` · `owner` |
| API Security | Helmet.js, CORS, parameterized SQL queries |
| Secrets | GitHub Secrets — no credentials in code |

---

## 🚀 CI/CD Pipelines

Three automated pipelines power the entire delivery process:

| Pipeline | Trigger | What It Does |
|:---------|:--------|:-------------|
| **salon-app.yaml** | Push to `main` or manual | Build Flutter APK + AAB → **Publish to Google Play** (internal track) |
| **backend.yaml** | Push to `main` | Build Docker image → **SSH deploy to AWS EC2** via PM2 |
| **admin-web.yaml** | Push to `main` | Build Next.js → **Deploy to Vercel** |

### Mobile CI/CD Flow

```
git push main ──▶ GitHub Actions ──▶ Flutter Build ──▶ Sign AAB ──▶ Google Play Console
                       │                                               (internal testing)
                       ├── Java 17 + Flutter SDK
                       ├── Decode keystore from secrets
                       ├── Auto-increment versionCode
                       └── 8GB swap (R8 OOM prevention)
```

> 📖 **Full write-up**: [How I Built CI/CD to Google Play with GitHub Actions](CICD_GOOGLE_PLAY_BLOG.md)

---

## 🗄️ Database Schema

```sql
users                  service_categories        appointments
├── id (UUID)          ├── id                    ├── id
├── email (unique)     ├── name                  ├── user_id → users
├── password (bcrypt)  └── description           ├── service_id → services
├── role (RBAC)                                  ├── expert_id → experts
└── verified           services                  ├── appointment_date
                       ├── id                    ├── status (enum)
experts                ├── category_id           ├── payment_status
├── id                 ├── name                  └── created_at
├── name               ├── price
├── specialization     └── duration              notifications
└── avatar                                       ├── id
                       reviews                   ├── user_id → users
offers                 ├── id                    ├── title
├── id                 ├── user_id → users       ├── message
├── title              ├── rating                └── read (boolean)
├── discount           └── comment
└── expires_at
```

---

## 🔌 API Reference

<details>
<summary><strong>🔑 Authentication</strong></summary>

<br/>

| Method | Endpoint | Description | Auth |
|:-------|:---------|:------------|:-----|
| `POST` | `/api/v1/auth/register` | Register with email + OTP | — |
| `POST` | `/api/v1/auth/verify-email` | Verify 6-digit OTP | — |
| `POST` | `/api/v1/auth/login` | Login → JWT tokens | — |
| `POST` | `/api/v1/auth/refresh-token` | Refresh access token | 🔑 |
| `POST` | `/api/v1/auth/forgot-password` | Request password reset | — |
| `POST` | `/api/v1/auth/reset-password` | Reset with OTP | — |
| `GET` | `/api/v1/auth/profile` | Get current user profile | 🔑 |

</details>

<details>
<summary><strong>💇 Services</strong></summary>

<br/>

| Method | Endpoint | Description | Auth |
|:-------|:---------|:------------|:-----|
| `GET` | `/api/v1/categories` | List all categories | — |
| `GET` | `/api/v1/services` | List all services | — |
| `GET` | `/api/v1/services/:id` | Get service details | — |
| `POST` | `/api/v1/services` | Create service | 🔑 Admin |
| `PUT` | `/api/v1/services/:id` | Update service | 🔑 Admin |
| `DELETE` | `/api/v1/services/:id` | Delete service | 🔑 Admin |

</details>

<details>
<summary><strong>📅 Appointments</strong></summary>

<br/>

| Method | Endpoint | Description | Auth |
|:-------|:---------|:------------|:-----|
| `POST` | `/api/v1/appointments` | Book appointment | 🔑 |
| `GET` | `/api/v1/appointments/my` | User's appointments | 🔑 |
| `GET` | `/api/v1/appointments` | All appointments | 🔑 Admin |
| `PUT` | `/api/v1/appointments/:id/status` | Update status | 🔑 Admin |
| `PUT` | `/api/v1/appointments/:id/pay` | Mark as paid | 🔑 Admin |
| `DELETE` | `/api/v1/appointments/:id/cancel` | Cancel appointment | 🔑 |

</details>

<details>
<summary><strong>📊 Dashboard</strong></summary>

<br/>

| Method | Endpoint | Description | Auth |
|:-------|:---------|:------------|:-----|
| `GET` | `/api/v1/dashboard/stats` | Statistics overview | 🔑 Admin |

</details>

---

## 📋 Getting Started

<details>
<summary><strong>Prerequisites</strong></summary>

<br/>

- Node.js 18+
- PostgreSQL 16+
- Flutter 3.x+
- npm or yarn

</details>

<details>
<summary><strong>Backend Setup</strong></summary>

<br/>

```bash
cd backend
npm install
createdb salon_db
psql -d salon_db -f database/schema.sql
cp .env.example .env          # configure your variables
npm run dev                    # http://localhost:5000
```

</details>

<details>
<summary><strong>Admin Web Setup</strong></summary>

<br/>

```bash
cd admin-web
npm install
cp .env.local.example .env.local
npm run dev                    # http://localhost:3001
```

</details>

<details>
<summary><strong>Mobile App Setup</strong></summary>

<br/>

```bash
cd salon-app
flutter pub get
flutter run                    # launches on connected device/emulator
```

> Update `API_BASE_URL` in your `.env` to point to your backend.

</details>

---

## 📊 Business Logic

```
  User books appointment (mobile)
            │
     ┌──────┴──────┐
     │              │
  Pay Now       Pay Later
     │              │
  ✅ Confirmed    ⏳ Reserved (4hr window)
  💳 Paid              │
                  ┌────┴────┐
                  │         │
              Paid within   Not paid
              4 hours       in 4 hours
                  │         │
              ✅ Confirmed  ❌ Auto-cancelled
                            📧 Reminder at 3hrs
```

---

## 🗺️ Roadmap

| Status | Feature |
|:------:|:--------|
| ✅ | Core booking system |
| ✅ | Email OTP verification |
| ✅ | RBAC (user / admin / owner) |
| ✅ | CI/CD → Google Play |
| ✅ | CI/CD → AWS EC2 (Docker) |
| ✅ | CI/CD → Vercel |
| ✅ | Push notifications (FCM) |
| 🔜 | Stripe payment integration |
| 🔜 | SMS notifications (Twilio) |
| 🔜 | Reviews & ratings |
| 🔜 | Loyalty program |
| 🔜 | Multi-language support |
| 🔜 | Advanced analytics |

---

## 📄 Documentation

| Document | Description |
|:---------|:------------|
| [Technical Decisions](docs/TECHNICAL_DECISIONS.md) | Why Stripe, EC2 vs Lambda, PostgreSQL, S3, and more |
| [CI/CD Blog](CICD_GOOGLE_PLAY_BLOG.md) | Step-by-step: GitHub Actions → Google Play |
| [Admin Web CI/CD to Vercel](ADMIN_WEB_VERCEL_CICD_BLOG.md) | How we wired GitHub Actions → Vercel and debugged path/output issues |
| [Architecture](ARCHITECTURE.md) | System design diagrams |
| [RBAC Guide](RBAC_IMPLEMENTATION_GUIDE.md) | Role-based access control implementation |
| [Backend API Reference](backend/API_REFERENCE.md) | Detailed endpoint documentation |
| [Merry Queen Privacy Policy](salon-app/PRIVACY_POLICY.md) | How the mobile app collects, uses, and shares data |
| [Troubleshooting](TROUBLESHOOTING_CONNECTION.md) | Common issues and fixes |
| [Deployment Guide](DEPLOYMENT.md) | Production deployment instructions |

---

<div align="center">

**Built by [Aztrosys](https://github.com/binasad/queen-s-marry)**

![MIT License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)

⭐ **Star this repository if you find it useful!**

</div>
