# Google Sign-In Setup Guide

If Google Sign-In is not working, follow these steps:

## 1. Add SHA-1 Fingerprint to Firebase

Your `google-services.json` has empty `oauth_client` - this means Google Sign-In cannot get credentials.

**Steps:**
1. Get your debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or for the default debug keystore:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. Go to [Firebase Console](https://console.firebase.google.com) → **marry-queen** project
3. Project Settings (gear) → Your apps → Android app (com.example.salon)
4. Click **Add fingerprint** → paste SHA-1 and SHA-256
5. **Download** the updated `google-services.json` and replace `android/app/google-services.json`

## 2. Enable Google Sign-In in Firebase Auth

1. Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Google** provider
3. Add support email if prompted

## 3. Add Web Client ID (for backend verification)

Your backend verifies the idToken using Firebase Admin. For reliable idToken, add the Web OAuth client ID:

1. Go to [Google Cloud Console](https://console.cloud.google.com) → select **marry-queen** project
2. **APIs & Services** → **Credentials**
3. Under **OAuth 2.0 Client IDs**:
   - If you see **Web client** – copy its Client ID
   - If not: **Create Credentials** → **OAuth client ID** → **Web application** → Create
4. Add to your `.env` file:
   ```
   GOOGLE_WEB_CLIENT_ID=229108556395-xxxxxx.apps.googleusercontent.com
   ```

## 4. Backend: Firebase Admin SDK (required for 500 → fix)

The backend returns 500 when Firebase Admin cannot verify the idToken. Fix:

- **Local dev:** Place `firebase-admin-sdk.json` in the backend root (Firebase Console → Project Settings → Service accounts → Generate new key)
- **Remote/Docker:** Set env var `FIREBASE_ADMIN_SDK_JSON` to the full JSON string (same service account). The file is often not deployed to production servers.

## 5. Rebuild the App

After changing `google-services.json`:
```bash
flutter clean
flutter pub get
flutter run
```
