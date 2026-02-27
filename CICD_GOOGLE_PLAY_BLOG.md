# How I Built a CI/CD Pipeline to Google Play Console Using GitHub Actions & Google Cloud

*A step-by-step guide from a real production Flutter app deployment*

---

## Introduction

Manually building APKs, signing them, and uploading AAB files to the Google Play Console every time you push a code change is tedious and error-prone. I wanted a single `git push` to automatically build my Flutter app, sign it, and publish it to Google Play's internal testing track — zero manual work.

In this blog, I'll walk you through exactly how I set this up for **Merry Queen**, a salon booking app built with Flutter, using **GitHub Actions** and a **Google Cloud service account**.

---

## The End Result

After this setup, here's what happens:

1. I push code to the `main` branch (or trigger manually from GitHub)
2. GitHub Actions spins up a runner
3. Flutter builds a signed APK + AAB
4. The AAB is automatically published to Google Play's **internal testing** track
5. I get downloadable artifacts (APK + AAB) stored for 30 days

No manual uploads. No Play Console browser tabs. Just push and ship.

---

## Prerequisites

Before diving in, you'll need:

- A **Flutter** project with Android support
- A **GitHub** repository
- A **Google Play Console** developer account
- Your app's **first AAB already uploaded manually** (Google requires the first upload to be manual)
- A **release keystore** (`.jks` file) for signing your app

---

## Step 1: Create a Google Cloud Service Account

This is the bridge between GitHub Actions and Google Play. The service account allows automated tools to upload builds on your behalf.

### 1.1 Go to Google Cloud Console

Navigate to [console.cloud.google.com](https://console.cloud.google.com) and select (or create) the project linked to your Play Console.

### 1.2 Create the Service Account

1. Go to **IAM & Admin → Service Accounts**
2. Click **Create Service Account**
3. Give it a descriptive name, e.g., `push-code-to-google-play-store`
4. Skip the optional permissions step (Play Console handles permissions)
5. Click **Done**

### 1.3 Generate a JSON Key

1. Click on the newly created service account
2. Go to the **Keys** tab
3. Click **Add Key → Create new key → JSON**
4. Download the JSON file — you'll need the entire contents later

### 1.4 Grant Access in Google Play Console

1. Go to [play.google.com/console](https://play.google.com/console)
2. Navigate to **Setup → API access**
3. Link your Google Cloud project if not already linked
4. Find your service account and click **Manage permissions**
5. Grant **Release manager** or at minimum:
   - **Release to production, exclude devices, and use Play App Signing**
   - **Manage testing tracks**
6. Apply to your specific app

> **Important**: It can take up to 24 hours for permissions to fully propagate, though it's usually much faster.

---

## Step 2: Prepare Your Signing Keystore

Google Play requires every release to be signed with the same key. In CI, we can't just drop a file on the runner — we encode it as a base64 string and decode it during the build.

### 2.1 Encode Your Keystore

```powershell
# PowerShell (Windows)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\merryqueen-release.jks")) | Set-Content keystore_base64.txt
```

```bash
# Linux / macOS
base64 -w 0 path/to/merryqueen-release.jks > keystore_base64.txt
```

Copy the entire contents of `keystore_base64.txt` — you'll paste this into a GitHub secret.

> **Warning**: Delete `keystore_base64.txt` after you've saved it as a GitHub secret. Never commit this file.

---

## Step 3: Configure GitHub Secrets

Go to your GitHub repo → **Settings → Secrets and variables → Actions** and add these secrets:

| Secret Name | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded keystore string |
| `KEY_ALIAS` | Your keystore alias (e.g., `merryqueen`) |
| `KEY_PASSWORD` | Keystore key password |
| `STORE_PASSWORD` | Keystore store password |
| `API_BASE_URL` | Your backend API URL (for `.env`) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | The **entire JSON contents** of the service account key file |

---

## Step 4: Create the GitHub Actions Workflow

Create `.github/workflows/salon-app.yaml` in your repository root:

```yaml
name: Salon App CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'salon-app/**'
  pull_request:
    branches: [main]
    paths:
      - 'salon-app/**'
  workflow_dispatch:  # Manual trigger from GitHub UI

jobs:
  build-android:
    name: Build Android (APK + AAB)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: salon-app

    env:
      GRADLE_OPTS: -Dorg.gradle.jvmargs="-Xmx4096m -XX:MaxMetaspaceSize=512m"
      JAVA_OPTS: -Xmx4096m

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Increase swap space
        uses: actionhippie/swap-space@v1
        with:
          size: 8G

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Create .env
        run: |
          echo "API_BASE_URL=${{ secrets.API_BASE_URL }}" > .env

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/merryqueen-release.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << 'EOF'
          storePassword=${{ secrets.STORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=merryqueen-release.jks
          EOF

      - name: Install dependencies
        run: flutter pub get

      - name: Set build number
        run: |
          BUILD_NUMBER=${{ github.run_number }}
          echo "Using versionCode=$BUILD_NUMBER"
          echo "BUILD_NUMBER=$BUILD_NUMBER" >> $GITHUB_ENV

      - name: Build release APK
        run: flutter build apk --release --build-number=${{ env.BUILD_NUMBER }}

      - name: Build release App Bundle
        run: flutter build appbundle --release --build-number=${{ env.BUILD_NUMBER }}

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: salon-app/build/app/outputs/flutter-apk/app-release.apk
          retention-days: 30

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: app-release-aab
          path: salon-app/build/app/outputs/bundle/release/app-release.aab
          retention-days: 30

      - name: Publish to Google Play
        if: >-
          (github.event_name == 'push' || github.event_name == 'workflow_dispatch')
          && github.ref == 'refs/heads/main'
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.aztrosys.merryqueen
          releaseFiles: salon-app/build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed
```

Let me break down the key decisions in this workflow.

---

## Step 5: Understanding the Key Design Decisions

### Trigger Strategy

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'salon-app/**'
  pull_request:
    branches: [main]
    paths:
      - 'salon-app/**'
  workflow_dispatch:
```

- **Push to main**: Auto-builds and publishes — but only when files inside `salon-app/` change. Backend or docs changes won't trigger a Flutter build.
- **Pull requests**: Builds only (no publish) — great for verifying the build doesn't break before merging.
- **Manual trigger**: The `workflow_dispatch` lets you hit "Run workflow" from the GitHub Actions tab anytime.

### Auto-Incrementing Version Code

```yaml
BUILD_NUMBER=${{ github.run_number }}
```

Google Play rejects uploads with duplicate `versionCode`. Instead of manually bumping it in `pubspec.yaml`, I use `github.run_number` — a counter that automatically increments with every workflow run. Run #1 = versionCode 1, Run #42 = versionCode 42. Simple and reliable.

### Conditional Publishing

```yaml
if: >-
  (github.event_name == 'push' || github.event_name == 'workflow_dispatch')
  && github.ref == 'refs/heads/main'
```

This ensures we only publish to Google Play on main branch events (push or manual). Pull requests build and verify but never touch the Play Store.

### OOM Prevention

GitHub Actions runners come with ~7GB RAM. Flutter + Gradle + R8 minification is memory-hungry. I hit `java.lang.OutOfMemoryError: Java heap space` on my first CI run. The fix was two-fold:

1. **Bump JVM heap to 4GB** via `GRADLE_OPTS` and `JAVA_OPTS`
2. **Add 8GB swap space** using `actionhippie/swap-space@v1`

Without these, the R8 minification step (which shrinks and obfuscates your Kotlin/Java code) will crash on complex projects.

### Keystore Handling

Never commit your keystore to Git. Instead:
1. Base64-encode it locally
2. Store the string as a GitHub secret (`KEYSTORE_BASE64`)
3. Decode it on the runner during build time

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/merryqueen-release.jks
```

The file only exists on the ephemeral runner and is destroyed after the job completes.

---

## Step 6: The Gradle Side (build.gradle.kts)

Your `android/app/build.gradle.kts` needs to read signing config from `key.properties`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

---

## Problems I Hit (and How I Fixed Them)

### Problem 1: OOM During R8 Minification

**Error**: `java.lang.OutOfMemoryError: Java heap space` at `:app:minifyReleaseWithR8`

**Fix**: Increased JVM heap to 4GB in `gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
```

And added 8GB swap in the workflow.

### Problem 2: Google Play Publish Step Was Skipped

After the first successful build, the "Publish to Google Play" step showed as **skipped**. The condition was:

```yaml
if: github.event_name == 'push'
```

I triggered the build manually via `workflow_dispatch`, which doesn't match `'push'`. The fix:

```yaml
if: (github.event_name == 'push' || github.event_name == 'workflow_dispatch') && github.ref == 'refs/heads/main'
```

### Problem 3: Version Code Conflicts

Google Play rejects duplicate `versionCode` values. Hardcoding it in `pubspec.yaml` means manual bumps every release. Using `github.run_number` as the `--build-number` flag eliminates this entirely.

---

## The Publish Flow Diagram

```
Developer pushes to main
        │
        ▼
GitHub Actions triggers
        │
        ▼
┌───────────────────┐
│  Checkout code     │
│  Setup Java 17     │
│  Setup Flutter     │
│  Add 8GB swap      │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Decode keystore   │
│  Write .env        │
│  Write key.props   │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  flutter pub get   │
│  flutter build apk │
│  flutter build aab │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Upload artifacts  │
│  (APK + AAB)       │
└────────┬──────────┘
         │
         ▼
┌───────────────────────┐
│  Publish AAB to       │
│  Google Play Console  │
│  (internal track)     │
└───────────────────────┘
```

---

## Cost & Performance

- **Build time**: ~12-15 minutes (Flutter build + Gradle compilation + R8)
- **GitHub Actions**: Free for public repos, 2,000 minutes/month for private repos on the free plan
- **Google Cloud**: The service account is free — no charges for the Play Developer API
- **Storage**: Artifacts retained for 30 days (configurable)

---

## What's Next?

Once you have this foundation, you can extend it:

- **Add `flutter test`** before the build step to run unit tests
- **Promote to production track** by changing `track: internal` to `track: production`
- **Add iOS builds** using a macOS runner
- **Slack/Discord notifications** on build success or failure
- **Code coverage** reporting with Codecov or Coveralls

---

## Summary

Setting up CI/CD from GitHub to Google Play Console involves:

1. **Google Cloud**: Create a service account with a JSON key
2. **Google Play Console**: Grant the service account release permissions
3. **GitHub Secrets**: Store your keystore (base64), passwords, and service account JSON
4. **GitHub Actions**: Write a workflow that builds, signs, and publishes your Flutter AAB
5. **Gradle**: Read signing config from `key.properties` (generated at build time)

The entire setup took about 2 hours including debugging OOM issues. Now every push to `main` delivers a new build to internal testers automatically — and I never have to open the Play Console to upload an AAB again.

---

*Built with Flutter, GitHub Actions, and Google Cloud for the Merry Queen salon booking app by Aztrosys.*
