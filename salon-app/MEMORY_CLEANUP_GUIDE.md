# Memory & Disk Cleanup Guide

## 📱 Flutter App Runtime Memory (RAM)

If the **salon app uses too much RAM** when running:

### Optimizations Already Applied
- **CachedNetworkImage** uses `memCacheWidth`/`memCacheHeight` (400px) so images decode at display size (~4x less memory per image).
- **Image cache limits** in `main.dart`: max 150 images, 80 MB (default is 1000 images, 100MB).
- **CachedImageWidget** used for service/category images instead of raw `Image.network`.

### Additional Tips
1. **Use profile/release mode** when measuring: `flutter run --profile` (debug adds ~50% overhead).
2. **Remove unused Firebase packages** from `pubspec.yaml` if you're not using Firestore/Database/Messaging.
3. **Compress large assets**: Run `flutter pub run flutter_svg` or use TinyPNG for JPG/PNG in `assets/`.
4. **Lazy-load Lottie**: Don't load all Lottie files at once; load only when the screen is shown.

### Check App Memory
```bash
flutter run --profile
# Then open DevTools → Memory tab, take heap snapshots
```

---

## 🧹 C Drive / Disk Space Issues

When running Flutter app, Node.js backend, and Next.js web, these locations can fill up your C drive:

### 1. **Flutter Build Artifacts** (Largest Impact)
**Location:** `C:\Users\[YourName]\.gradle\`
**Size:** Can be 5-10 GB+
**Cleanup:**
```powershell
# Clean Flutter build
cd salon-app
flutter clean

# Clean Gradle cache (WARNING: Will require re-downloading dependencies)
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"
```

### 2. **Flutter Build Folders**
**Location:** `salon-app\build\` and `salon-app\android\build\`
**Size:** 500MB - 2GB
**Cleanup:**
```powershell
cd salon-app
flutter clean
# This removes build/ folder
```

### 3. **Node.js node_modules** (Backend & Admin-Web)
**Location:** 
- `backend\node_modules\` (~200-500MB)
- `admin-web\node_modules\` (~300-800MB)
- `admin-web\.next\` (~100-300MB)

**Cleanup:**
```powershell
# Backend
cd backend
Remove-Item -Recurse -Force node_modules
npm install  # Reinstall when needed

# Admin-Web
cd admin-web
Remove-Item -Recurse -Force node_modules
Remove-Item -Recurse -Force .next
npm install  # Reinstall when needed
```

### 4. **Flutter Pub Cache**
**Location:** `C:\Users\[YourName]\AppData\Local\Pub\Cache\`
**Size:** 1-3 GB
**Cleanup:**
```powershell
flutter pub cache repair
# Or manually:
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache"
flutter pub get  # Will re-download
```

### 5. **Android SDK & Emulator**
**Location:** `C:\Users\[YourName]\AppData\Local\Android\`
**Size:** 10-20 GB (if you have emulators)
**Cleanup:**
- Delete unused emulators in Android Studio
- Or: `flutter emulators --delete <emulator_id>`

### 6. **Log Files**
**Location:** Various
**Cleanup:**
```powershell
# Backend logs
cd backend
Remove-Item -Force *.log
Remove-Item -Recurse -Force logs\

# Flutter logs
cd salon-app
Remove-Item -Recurse -Force .dart_tool\flutter_build\
```

## 🚀 Quick Cleanup Script

Create `cleanup.ps1` in project root:

```powershell
# Flutter Cleanup
Write-Host "Cleaning Flutter..." -ForegroundColor Green
cd salon-app
flutter clean
cd ..

# Backend Cleanup
Write-Host "Cleaning Backend..." -ForegroundColor Green
cd backend
if (Test-Path node_modules) {
    Remove-Item -Recurse -Force node_modules
    Write-Host "Removed backend node_modules" -ForegroundColor Yellow
}
cd ..

# Admin-Web Cleanup
Write-Host "Cleaning Admin-Web..." -ForegroundColor Green
cd admin-web
if (Test-Path node_modules) {
    Remove-Item -Recurse -Force node_modules
    Write-Host "Removed admin-web node_modules" -ForegroundColor Yellow
}
if (Test-Path .next) {
    Remove-Item -Recurse -Force .next
    Write-Host "Removed .next build folder" -ForegroundColor Yellow
}
cd ..

Write-Host "Cleanup complete! Run 'npm install' and 'flutter pub get' when needed." -ForegroundColor Green
```

## 📊 Disk Space Analysis

Check what's taking space:
```powershell
# Check Flutter build size
Get-ChildItem -Path "salon-app\build" -Recurse | Measure-Object -Property Length -Sum

# Check node_modules size
Get-ChildItem -Path "backend\node_modules" -Recurse | Measure-Object -Property Length -Sum
Get-ChildItem -Path "admin-web\node_modules" -Recurse | Measure-Object -Property Length -Sum

# Check Gradle cache
Get-ChildItem -Path "$env:USERPROFILE\.gradle" -Recurse | Measure-Object -Property Length -Sum
```

## ⚠️ What NOT to Delete

- `.git/` folders
- `pubspec.yaml`, `package.json` files
- Source code files
- `.env` files (but they're in .gitignore)

## 🔄 Regular Maintenance

Run cleanup weekly:
1. `flutter clean` after major changes
2. Delete `.next` folder in admin-web after builds
3. Clear Gradle cache monthly: `Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"`
