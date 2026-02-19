# Stripe Webhook Setup – Appointments Not Showing in Admin-Web

When customers pay via Stripe, the appointment is created by the **webhook**, not by the create-intent. If the webhook is not configured or fails, no appointment is created and nothing appears in admin-web.

## 1. Run the database migration

Ensure the `payment_intent_id` column exists:

```bash
# In Supabase SQL Editor or psql, run:
```

```sql
-- From backend/database/add_payment_intent_id.sql
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) UNIQUE;

CREATE INDEX IF NOT EXISTS idx_appointments_payment_intent ON appointments(payment_intent_id)
WHERE payment_intent_id IS NOT NULL;
```

## 2. Configure Stripe webhook

1. Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **Add endpoint**
3. **Endpoint URL:** Use your backend URL + `/api/v1/payments/webhook`  
   - Example: `https://aztrosyssalonappapi.ddns.net/api/v1/payments/webhook`
   - **Verify URL:** Visit `GET https://YOUR_DOMAIN/api/v1/payments/webhook` in a browser – it returns the exact URL to use
   - Stripe requires HTTPS in production
4. **Events to send:** Select `payment_intent.succeeded`
5. Click **Add endpoint**
6. Copy the **Signing secret** (starts with `whsec_`)

## 3. Add webhook secret to .env

```env
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxx
```

Restart the backend after updating `.env`.

## 4. Verify it works

1. Make a test payment from the mobile app
2. Check backend logs for:
   - `📥 Stripe webhook received`
   - `📥 Webhook event type: payment_intent.succeeded`
   - `✅ Webhook: created appointment ... - will appear in admin-web`
3. If you see `❌ Webhook signature verification failed` → wrong `STRIPE_WEBHOOK_SECRET`
4. If you see `column "payment_intent_id" does not exist` → run the migration in step 1

## 5. Admin-web appointments

- Admin fetches via `GET /api/v1/appointments`
- Requires `appointments.manage_all` permission
- Check backend logs for `📋 Admin fetching appointments` and `📋 Appointments query returned X rows`
