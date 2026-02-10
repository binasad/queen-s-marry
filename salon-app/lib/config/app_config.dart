import 'package:flutter/foundation.dart';

class AppConfig {
  // Development: emulator/physical device hitting local backend
  // Use environment variable or default to Android emulator
  static const String devBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://44.215.209.41:5000/api/v1', // AWS EC2 backend
  );

  static const String devWebBaseUrl =
      'http://44.215.209.41:5000/api/v1'; // AWS EC2 backend for web/desktop

  // Optional: override for physical device over LAN (set via --dart-define)
  // Example: flutter run --dart-define=DEV_DEVICE_BASE_URL=http://YOUR_IP:5000/api/v1
  static const String devDeviceBaseUrl = String.fromEnvironment(
    'DEV_DEVICE_BASE_URL',
    defaultValue:
        'http://44.215.209.41:5000/api/v1', // AWS EC2 backend for physical devices
  );

  // Production
  static const String prodBaseUrl = 'http://44.215.209.41:5000/api/v1';

  // Toggle this for prod
  static const bool isProduction = true;

  static String get baseUrl {
    if (isProduction) return prodBaseUrl;
    // Web uses localhost; Android emulator uses 10.0.2.2; physical devices can supply a LAN URL via dart-define
    if (kIsWeb) return devWebBaseUrl;
    if (devDeviceBaseUrl.isNotEmpty) return devDeviceBaseUrl;
    return devBaseUrl;
  }
}
