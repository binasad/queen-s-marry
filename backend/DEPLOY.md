# Backend Deployment Guide

## Deployment Flow (AWS EC2)

1. **GitHub Actions** builds Docker image and pushes to Docker Hub
2. **SSH to EC2** pulls the image and runs it with env from `ENV_FILE` secret
3. **Docker run** uses `--env-file` so all vars from `.env` go to the container

## GitHub Secrets Required

| Secret | Purpose |
|--------|---------|
| `ENV_FILE` | **Full content** of backend `.env` – DB, JWT, S3, SMTP, `GOOGLE_WEB_CLIENT_ID`, etc. |
| `FIREBASE_ADMIN_SDK_JSON` | Firebase service account JSON (for push notifications) |
| `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY` | SSH to EC2 |
| `DOCKER_HUB_USERNAME`, `DOCKER_HUB_TOKEN` | Docker Hub registry |

## When to Update ENV_FILE

After adding or changing `.env` vars locally, update the `ENV_FILE` secret:

1. Copy the full contents of `backend/.env` (including new vars)
2. GitHub → **Settings** → **Secrets and variables** → **Actions**
3. Edit `ENV_FILE` → Paste new content → **Update secret**
4. Redeploy (Actions → Backend CI/CD → Run workflow)

## Google Sign-In (GOOGLE_WEB_CLIENT_ID)

Add to your local `.env` and include it in `ENV_FILE`:

```
GOOGLE_WEB_CLIENT_ID=229108556395-h62rnber6r8mlcmsri605k93v4fce1a5.apps.googleusercontent.com
```

Get it from: [Google Cloud Console](https://console.cloud.google.com) → marry-queen → APIs & Services → Credentials → OAuth 2.0 Web client.

## Firebase Push Notifications

1. [Firebase Console](https://console.firebase.google.com/) → Project settings → Service accounts → Generate new private key
2. Add GitHub Secret `FIREBASE_ADMIN_SDK_JSON` with the full JSON (minify to one line)
