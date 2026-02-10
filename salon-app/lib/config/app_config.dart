import 'package:flutter/foundation.dart';

class AppConfig {
  // Development: emulator/physical device hitting local backend
  // Use environment variable or default to Android emulator
  static const String devBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://192.168.18.110:5000/api/v1', // Android emulator default
  );
  
  static const String devWebBaseUrl =
      'http://localhost:5000/api/v1'; // Web/desktop

  // Optional: override for physical device over LAN (set via --dart-define)
  // Example: flutter run --dart-define=DEV_DEVICE_BASE_URL=http://YOUR_IP:5000/api/v1
  static const String devDeviceBaseUrl = String.fromEnvironment(
    'DEV_DEVICE_BASE_URL',
    defaultValue: '', // Set via --dart-define for physical devices
  );

  // Production
  static const String prodBaseUrl = 'https://api.yoursalon.com/api/v1';

  // Toggle this for prod
  static const bool isProduction = false;

  static String get baseUrl {
    if (isProduction) return prodBaseUrl;
    // Web uses localhost; Android emulator uses 10.0.2.2; physical devices can supply a LAN URL via dart-define
    if (kIsWeb) return devWebBaseUrl;
    if (devDeviceBaseUrl.isNotEmpty) return devDeviceBaseUrl;
    return devBaseUrl;
  }
}
