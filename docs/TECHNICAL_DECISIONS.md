# Technical Decisions & Problem-Solving

This document explains **why** we chose each technology and **what problems** they solve. It demonstrates deliberate, problem-driven architecture.

---

## 1. Stripe Webhook vs. Client-Only Payment Confirmation

### Problem
When a customer pays via Stripe, the mobile app confirms payment locally. But the app can crash, lose network, or close before telling our server. **How do we reliably create the appointment in our database?**

### Solution: Webhook + Client Fallback

| Approach | Problem it solves |
|----------|-------------------|
| **Stripe Webhook** | Stripe sends `payment_intent.succeeded` to our server **from their side**. Even if the app dies, our server receives the event and creates the appointment. Single source of truth. |
| **Client Fallback** | Webhooks can fail (wrong URL, firewall, Stripe outage). When the app confirms payment, it calls `POST /payments/confirm-appointment` so we create the appointment immediately. Idempotent—if webhook already ran, we skip. |

### Why Webhook First?
- **Reliability**: Payment confirmation comes from Stripe, not the client (which can lie or fail).
- **Idempotency**: `payment_intent_id` ensures we never create duplicate appointments.
- **Audit trail**: Webhook events are logged; we can reconcile with Stripe Dashboard.

---

## 2. EC2 vs. AWS Lambda

### Problem
We need a server to run the Node.js API 24/7. Should we use Lambda (serverless) or EC2?

### Decision: EC2

| Factor | EC2 | Lambda |
|--------|-----|--------|
| **WebSockets** | ✅ Native support (Socket.IO for real-time admin updates) | ❌ No persistent connections |
| **Long-running** | ✅ Always on; no cold starts | ❌ 15-min max; cold starts hurt UX |
| **Stripe Webhooks** | ✅ Raw body for signature verification; simple | ⚠️ API Gateway + Lambda adds complexity |
| **Cost at low scale** | Predictable (t3.small ~$15/mo) | Pay-per-invocation; can be cheaper at tiny scale |
| **Docker** | ✅ Same image locally and in prod | ❌ Different packaging (containers vs. zip) |

### Why EC2 Fits This Project
- **WebSockets** for admin dashboard (live appointment updates) require a long-lived connection.
- **Stripe webhooks** need raw request body; Express handles this cleanly.
- **Docker** gives us identical dev/prod behavior.
- At salon scale (hundreds of bookings/month), EC2 cost is acceptable and operations are simpler.

---

## 3. S3 for File Storage

### Problem
Users upload profile photos; admins upload service images. Where do we store them?

### Options Considered

| Option | Pros | Cons |
|--------|------|-----|
| **Local disk (EC2)** | Simple | Lost on instance replace; no CDN; no backup |
| **Database (BLOB)** | Single source | Bloats DB; slow queries; expensive backups |
| **S3** | Durable, scalable, CDN-ready, cheap | Requires IAM setup |

### Decision: S3

### Problems S3 Solves
1. **Durability**: 99.999999999% (11 nines). Files survive instance failure.
2. **Scalability**: Unlimited storage; no "disk full" alerts.
3. **Cost**: ~$0.023/GB/month; far cheaper than DB storage.
4. **CDN**: Can add CloudFront for fast global delivery.
5. **Separation of concerns**: DB stays lean; media lives in object storage.

---

## 4. PostgreSQL vs. MongoDB / MySQL

### Problem
We need a database for users, appointments, services, reviews. Which DB?

### Decision: PostgreSQL

| Requirement | How PostgreSQL Solves It |
|-------------|--------------------------|
| **Relationships** | Appointments → users, services, offers. PostgreSQL's foreign keys enforce integrity; no orphan records. |
| **Transactions** | "Create appointment + send email" must be atomic. `BEGIN`/`COMMIT` with rollback on failure. |
| **Complex queries** | Dashboard stats: `COUNT(*) FILTER (WHERE status = 'paid')`, revenue by date, top services. PostgreSQL excels at analytical SQL. |
| **ACID** | Payment recorded = appointment confirmed. No partial writes. |
| **JSON when needed** | `tags TEXT[]` for services; can use `jsonb` for flexible fields. |

### Why Not MongoDB?
- Strong relational model (users, appointments, services) fits SQL better.
- Joins and aggregations are simpler in PostgreSQL for reporting.
- Supabase (PostgreSQL) gives us auth, real-time, and managed backups out of the box.

---

## 5. Supabase (Managed PostgreSQL) vs. Self-Hosted DB

### Problem
We need PostgreSQL. Run it ourselves on EC2 or use a managed service?

### Decision: Supabase

| Factor | Supabase | Self-Hosted on EC2 |
|--------|----------|--------------------|
| **Backups** | Automated, point-in-time recovery | Manual setup; risk of data loss |
| **Scaling** | Connection pooling built-in | We'd need PgBouncer |
| **Maintenance** | Patches, upgrades handled | We manage everything |
| **Cost** | Free tier; paid plans predictable | EC2 + EBS + our time |

### Problem Solved
We focus on application logic, not DB ops. Supabase handles backups, failover, and connection pooling.

---

## 6. JWT vs. Session Cookies

### Problem
Mobile app + web admin need auth. How do we authenticate API requests?

### Decision: JWT (Bearer token)

| Factor | JWT | Session Cookies |
|--------|-----|-----------------|
| **Mobile** | Store token; send in `Authorization` header | Cookies don't work well in Flutter/native apps |
| **Stateless** | No server-side session store | Requires Redis/DB for sessions |
| **Cross-domain** | Works for API + admin-web on different domains | CORS + cookie rules get messy |

### Problem Solved
One auth mechanism for mobile (Flutter) and web (Next.js). Stateless = no session store to scale.

---

## 7. Firebase (FCM) for Push Notifications

### Problem
Customers need real-time alerts: "Appointment confirmed", "Payment received". How do we push to phones?

### Decision: Firebase Cloud Messaging (FCM)

| Factor | FCM | Alternatives |
|--------|-----|---------------|
| **iOS + Android** | One SDK for both | Would need APNs + FCM separately |
| **Reliability** | Google infrastructure | Self-hosted push is complex |
| **Token management** | We store `fcm_token` in DB; backend sends via Firebase Admin SDK | Simple integration |
| **Cost** | Free | OneSignal, etc. have limits |

### Problem Solved
Reliable push to logged-in customers without building our own push infrastructure.

---

## 8. Terraform for Infrastructure

### Problem
We need EC2, S3, security groups. Manual setup is error-prone and not reproducible.

### Decision: Terraform (Infrastructure as Code)

| Benefit | What it solves |
|---------|----------------|
| **Reproducibility** | `terraform apply` creates identical env in dev/staging/prod |
| **Version control** | Infra changes are reviewed like code |
| **Disaster recovery** | Lose EC2? Run `terraform apply` to recreate |
| **Documentation** | `.tf` files document what we run |

### Problem Solved
Infrastructure is code. No "it works on my machine" for servers.

---

## Summary: Problem → Solution Map

| Problem | Solution |
|---------|----------|
| Reliable payment → appointment creation | Stripe webhook + client fallback |
| Real-time admin updates | EC2 + WebSockets (not Lambda) |
| Durable, scalable file storage | S3 |
| Relational data + complex queries | PostgreSQL |
| Managed DB, less ops | Supabase |
| Auth for mobile + web | JWT |
| Push to phones | Firebase FCM |
| Reproducible infrastructure | Terraform |
