# Push Notifications Troubleshooting

If customers are not receiving push notifications, check the following:

## 1. Firebase Configuration (salon-app)

**Critical:** `lib/firebase_options.dart` has placeholders for Android/iOS:
- `YOUR_ANDROID_APP_ID` 
- `YOUR_IOS_APP_ID`

**Fix:** In the salon-app directory, run:
```bash
flutterfire configure
```
This adds your app to the marry-queen Firebase project and updates firebase_options.dart with real app IDs. If the Android/iOS apps are not yet in Firebase Console, add them first at https://console.firebase.google.com → marry-queen → Project settings → Your apps.

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

## Quick Checklist

- [ ] `flutterfire configure` run in salon-app
- [ ] `fcm_token` column exists in users table
- [ ] `firebase-admin-sdk.json` in backend/
- [ ] Customer logged in with email/Google (not guest)
- [ ] Customer granted notification permission
- [ ] Flutter log shows "Token saved to backend"
- [ ] Backend log shows "Firebase Admin initialized"
