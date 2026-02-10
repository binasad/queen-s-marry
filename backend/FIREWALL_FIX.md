# Fix Windows Firewall for Android Emulator Connection

## Problem
Android emulator cannot connect to backend at `http://10.0.2.2:5000` - connection timeout.

## Solution 1: Allow Node.js through Windows Firewall (Recommended)

1. **Open Windows Defender Firewall:**
   - Press `Win + R`
   - Type: `wf.msc`
   - Press Enter

2. **Allow Node.js:**
   - Click "Inbound Rules" in the left panel
   - Look for "Node.js JavaScript Runtime" rules
   - If they exist, make sure they're enabled for "Private" networks
   - If they don't exist or are disabled:
     - Click "New Rule" in the right panel
     - Select "Program"
     - Browse to Node.js executable (usually `C:\Program Files\nodejs\node.exe`)
     - Select "Allow the connection"
     - Check "Private" (and optionally "Domain")
     - Give it a name: "Node.js - Allow Private Networks"
     - Click Finish

3. **Alternative: Allow Port 5000:**
   - Click "New Rule"
   - Select "Port"
   - Select "TCP" and enter port "5000"
   - Select "Allow the connection"
   - Check "Private"
   - Name it: "Backend API Port 5000"
   - Click Finish

## Solution 2: Use Your Computer's IP Address (For Physical Devices)

If using a **physical Android device** (not emulator):

1. **Find your computer's IP address:**
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" under your active network adapter (e.g., `192.168.1.100`)

2. **Update Flutter app configuration:**
   Run the app with:
   ```bash
   flutter run --dart-define=DEV_DEVICE_BASE_URL=http://YOUR_IP:5000/api/v1
   ```
   Replace `YOUR_IP` with your actual IP address.

## Solution 3: Test Connectivity

1. **From Android Emulator Browser:**
   - Open browser in emulator
   - Go to: `http://10.0.2.2:5000/health`
   - Should show: `{"success":true,"message":"Server is running"}`

2. **From Command Line (if adb is available):**
   ```bash
   adb shell
   curl http://10.0.2.2:5000/health
   ```

## Quick Test

After fixing firewall, restart the backend and try the app again. You should see in backend logs:
```
📥 [timestamp] - POST /api/v1/auth/login
   IP: ::ffff:10.0.2.2
   Origin: None (mobile app)
```

If you still see connection timeout, the firewall is still blocking it.
