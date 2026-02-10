# Connection Troubleshooting Guide

## Current Issue
Android emulator cannot connect to backend at `http://10.0.2.2:5000` - connection timeout.

## Solutions (Try in Order)

### ✅ Solution 1: Android Network Security Config (Just Added)
I've added the network security configuration to allow HTTP traffic. **Rebuild the app**:
```bash
cd salon-app
flutter clean
flutter pub get
flutter run
```

### ✅ Solution 2: Use Your Computer's IP Address
Your computer's IP is: **192.168.18.110**

**Option A: Update app_config.dart directly:**
```dart
static const String devBaseUrl = 'http://192.168.18.110:5000/api/v1';
```

**Option B: Run with dart-define:**
```bash
flutter run --dart-define=DEV_DEVICE_BASE_URL=http://192.168.18.110:5000/api/v1
```

### ✅ Solution 3: Windows Firewall (If not done yet)
1. Press `Win + R` → Type `wf.msc` → Enter
2. Inbound Rules → New Rule
3. Port → TCP → 5000
4. Allow connection → Private
5. Name: "Backend API Port 5000"

### ✅ Solution 4: Disable Windows Firewall Temporarily (For Testing Only)
**⚠️ WARNING: Only for testing, re-enable after!**

1. Press `Win + R` → Type `firewall.cpl` → Enter
2. Click "Turn Windows Defender Firewall on or off"
3. Turn off for Private networks (temporarily)
4. Test the app
5. **Re-enable firewall after testing!**

### ✅ Solution 5: Check Antivirus Software
Some antivirus software (Norton, McAfee, etc.) may block connections. Temporarily disable to test.

### ✅ Solution 6: Test from Emulator Browser
1. Open browser in Android emulator
2. Go to: `http://10.0.2.2:5000/health`
3. If this works, the app should also work
4. If this doesn't work, try: `http://192.168.18.110:5000/health`

## Quick Test Commands

**Test backend from command line:**
```powershell
# Test localhost
Invoke-WebRequest http://localhost:5000/health

# Test from your IP
Invoke-WebRequest http://192.168.18.110:5000/health
```

**Check if port is listening:**
```powershell
netstat -ano | findstr :5000
```

## What to Try Next

1. **Rebuild the app** (Solution 1 - network security config)
2. **Try using IP address** `192.168.18.110` instead of `10.0.2.2`
3. **Check backend logs** - are ANY requests coming through?
4. **Test from emulator browser** - can it reach the backend?

## Expected Result

After fixing, you should see in **backend console**:
```
📥 [timestamp] - POST /api/v1/auth/login
   IP: ::ffff:10.0.2.2 (or your IP)
   Origin: None (mobile app)
📝 Registration request received
   Email: ...
```

If you see this, the connection is working!
