# Push Notifications Troubleshooting

If customers are not receiving push notifications, check the following:

## 1. Firebase Configuration (salon-app) – ⚠️ MOST COMMON CAUSE

**Critical:** `lib/firebase_options.dart` has placeholders:
- Android: `appId: '1:229108556395:android:YOUR_ANDROID_APP_ID'`
- iOS: `appId: '1:229108556395:ios:YOUR_IOS_APP_ID'`

With these placeholders, `getToken()` returns **null** or an **invalid token**. FCM rejects it when the backend sends.

**Fix:**
1. Add your Android app in Firebase Console: https://console.firebase.google.com → marry-queen → Project settings → Add app → Android
   - Package name: `com.example.salon` (from android/app/build.gradle.kts)
   - Download `google-services.json` → place in `android/app/`
2. In salon-app directory, run: `flutterfire configure`
3. Rebuild: `flutter clean && flutter pub get`

---

## 2. Database Migration (backend)

The `users` table must have an `fcm_token` column.

**Check:** In your database:
```sql
SELECT column_name FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'fcm_token';
```

**Fix:** Run:
```bash
psql -U your_user -d your_db -f backend/database/add_fcm_token_column.sql
```

---

## 3. Backend Firebase Admin (backend)

The backend needs `firebase-admin-sdk.json` from the marry-queen project.

**Check:** File exists at `backend/firebase-admin-sdk.json`

**Fix:** Firebase Console → marry-queen → Project settings → Service accounts → Generate new private key. Save as `backend/firebase-admin-sdk.json`.

On server start you should see: `✅ Firebase Admin initialized for push notifications`
If you see `⚠️ firebase-admin-sdk.json not found`, notifications won't send.

---

## 4. Customer Must Be Registered (Not Guest)

Guests do not receive notifications. Customer must log in with email or Google.

---

## 5. Customer Must Grant Permission

- **Android 13+:** The app requests POST_NOTIFICATIONS at runtime. If the user denies, no notifications.
- **iOS:** User must tap "Allow" when prompted.

Check Flutter logs for: `PushNotificationService: Permission status = ...`

---

## 6. Token Must Be Saved

After login, the app calls `POST /notifications/save-token`. Check:
- Flutter logs: `PushNotificationService: ✅ Token saved to backend`
- If you see `❌ Save token failed`, check the error message.
- Backend: Run `SELECT id, email, fcm_token IS NOT NULL as has_token FROM users WHERE role_id IN (SELECT id FROM roles WHERE name IN ('Customer','User'));` to verify tokens are stored.

---

## 7. Appointment Must Have user_id

Push is sent only when `appointment.user_id` is set (i.e. booked by a registered user). Walk-in or admin-created appointments without a linked user won't get push.

---

## 8. Backend Logs

When sending, the backend logs:
- `📤 Push sent: [title]` = success
- `Push: No FCM token for user X` = user has no token saved
- `Push send error: ...` = FCM rejected (e.g. invalid/expired token)

---

## Test Push (Admin API)

To verify the full flow, send a test notification to a customer:

```bash
# Replace TOKEN with your admin JWT, USER_ID with the customer's user ID
curl -X POST "https://your-api/api/v1/notifications/test/USER_ID" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","body":"Can you see this?"}'
```

- **200 + notification received** → Backend & FCM work. Check appointment triggers.
- **400 "has no FCM token"** → Token not saved. Check Firebase config + Flutter logs.
- **500 "messaging/registration-token-not-registered"** → Token invalid/expired. Customer should reopen app (triggers token refresh).

## Diagnostic SQL

Run `backend/database/diagnose_push_notifications.sql` in your SQL editor to see which users have FCM tokens.

## Quick Checklist

- [ ] `flutterfire configure` run in salon-app (real app IDs, not YOUR_ANDROID_APP_ID)
- [ ] `google-services.json` in android/app/
- [ ] `fcm_token` column exists in users table
- [ ] `firebase-admin-sdk.json` in backend/
- [ ] Customer logged in with email/Google (not guest)
- [ ] Customer granted notification permission
- [ ] Flutter log shows "Token saved to backend"
- [ ] Backend log shows "Firebase Admin initialized"
