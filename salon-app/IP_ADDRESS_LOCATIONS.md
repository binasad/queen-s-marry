# IP Address Locations in Codebase

## 🔍 Where IP Addresses Are Used

### 1. **WebSocket Service** (`lib/services/websocket_service.dart`)

**Line 23:** Reads `BACKEND_URL` environment variable
```dart
final envUrl = const String.fromEnvironment('BACKEND_URL');
```

**Line 43:** Default fallback URL
```dart
return 'http://10.0.2.2:5000';  // Android emulator default
```

**Line 140-177:** Alternative connection logic (tries `192.168.18.110:5000` first, then `localhost:5000`)

### 2. **App Config** (`lib/config/app_config.dart`)

**Line 8:** Default backend URL (for API calls)
```dart
defaultValue: 'http://192.168.18.110:5000/api/v1'
```

**Line 12:** Web backend URL
```dart
'http://localhost:5000/api/v1'
```

### 3. **Android Network Security Config** (`android/app/src/main/res/xml/network_security_config.xml`)

**Line 15:** Allowed domain for HTTP traffic
```xml
<domain includeSubdomains="true">192.168.18.110</domain>
```

## ✅ Current Configuration

The app now uses `192.168.18.110:5000` as the standard IP address:
1. **WebSocket Service:** Tries `192.168.18.110:5000` as first alternative connection
2. **App Config:** Default API URL is `192.168.18.110:5000/api/v1`
3. **Network Security:** `192.168.18.110` is allowed in Android network config

## ✅ Solution

### Option 1: Remove from Command Line
If you're running with `--dart-define`, remove it:
```bash
# Instead of:
flutter run --dart-define=BACKEND_URL=http://192.168.1.100:5000/api/v1

# Use:
flutter run
# Or for physical device:
flutter run --dart-define=DEV_DEVICE_BASE_URL=http://YOUR_IP:5000/api/v1
```

### Option 2: Check VS Code Launch Config
Check `.vscode/launch.json` for `BACKEND_URL`:
```json
{
  "configurations": [
    {
      "args": [
        "--dart-define=BACKEND_URL=http://192.168.1.100:5000/api/v1"  // ← Remove this
      ]
    }
  ]
}
```

### Option 3: Check Android Studio Run Config
In Android Studio → Run → Edit Configurations → Check "Additional run args"

## 📝 Current Defaults

- **Android Emulator:** `10.0.2.2:5000` (WebSocket) / `192.168.18.110:5000/api/v1` (API)
- **Physical Device:** Use `--dart-define=DEV_DEVICE_BASE_URL=http://YOUR_IP:5000/api/v1`
- **Web:** `localhost:5000`

## 🔧 Current Implementation

The `_tryAlternativeConnection()` method tries:
1. `192.168.18.110:5000` (your computer's IP on local network)
2. `localhost:5000` (for web/debugging)

This ensures consistent connection attempts without relying on environment variables.
