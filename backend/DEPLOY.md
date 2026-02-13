# Backend Deployment Guide

## Automatic Deployment

Deployment runs automatically:
- **On push** to `main` when `backend/**` files change
- **Every 6 hours** (recovers from EC2 reboot)
- **Manually** via GitHub Actions → Backend CI/CD → Run workflow

## Firebase Push Notifications Setup

To enable push notifications, add the Firebase Admin SDK JSON to GitHub Secrets:

### Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Project settings** (gear icon) → **Service accounts**
4. Click **Generate new private key**
5. Download the JSON file

### Step 2: Add to GitHub Secrets

1. Open your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. **Name:** `FIREBASE_ADMIN_SDK_JSON`
4. **Value:** Paste the **entire** JSON content (minify to one line - remove newlines)

Example of minified JSON:
```json
{"type":"service_account","project_id":"your-project","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
```

### Step 3: Redeploy

Trigger deployment (Actions → Run workflow) or push a change to backend. The next deploy will include Firebase and push notifications will work.
