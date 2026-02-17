# Stripe Webhook Setup

Payment verification uses Stripe webhooks. The backend creates appointments only when Stripe confirms payment via `payment_intent.succeeded`.

## 1. Run the migration

```sql
-- In Supabase SQL Editor or psql
\i database/add_payment_intent_id.sql
```

Or run the contents of `database/add_payment_intent_id.sql`.

## 2. Configure environment

Add to your `.env`:

```
STRIPE_SECRET_KEY=sk_test_xxx          # or sk_live_xxx for production
STRIPE_WEBHOOK_SECRET=whsec_xxx        # from Stripe Dashboard
```

## 3. Get the webhook secret

### Production

1. Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/webhooks)
2. Add endpoint: `https://your-backend.com/api/v1/payments/webhook`
3. Select event: `payment_intent.succeeded`
4. Copy the **Signing secret** (starts with `whsec_`)

### Local development (Stripe CLI)

```bash
# Install Stripe CLI: https://stripe.com/docs/stripe-cli
stripe listen --forward-to localhost:5000/api/v1/payments/webhook
```

The CLI will output a webhook secret like `whsec_xxx` — use that in `.env` for local testing.

## 4. Flow

1. **App** → `POST /payments/create-intent` with booking metadata (serviceId, date, time, customer info)
2. **Backend** → Creates Stripe PaymentIntent with metadata
3. **User** → Pays via Stripe Payment Sheet in the app
4. **Stripe** → Sends `payment_intent.succeeded` webhook to your backend
5. **Backend** → Verifies signature, creates appointment, sends email & push notifications
