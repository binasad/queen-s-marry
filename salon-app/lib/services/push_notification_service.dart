import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';
import 'storage_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();

  Future<void> initialize() async {
    // Gatekeeper: Never init for guest users (privacy, cost, predictability)
    final isGuest = await _storage.isGuest();
    if (isGuest) {
      print('PushNotificationService: Skipping – Guest user detected.');
      await clearToken();
      return;
    }

    // 1. Request Permission (Required for iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('PushNotificationService: Permission status = ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Get the Token
      String? token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        print('PushNotificationService: ⚠️ FCM returned null/empty token. '
            'Ensure Firebase is configured (run: flutterfire configure)');
        return;
      }
      print('PushNotificationService: Token obtained (${token.length} chars)');

      await _saveTokenToBackend(token);

      // Listen for token refresh (e.g. app reinstall, cache clear)
      _fcm.onTokenRefresh.listen((newToken) async {
        print('PushNotificationService: Token refreshed, updating backend');
        await _saveTokenToBackend(newToken);
      });
    } else {
      print('PushNotificationService: Permission denied (${settings.authorizationStatus})');
    }

    // 3. Listen for messages while app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message: ${message.notification!.title}');
      }
    });
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _api.post(
        '/notifications/save-token',
        {'fcmToken': token},
        requiresAuth: true,
      );
      print('PushNotificationService: ✅ Token saved to backend');
    } catch (e) {
      print('PushNotificationService: ❌ Save token failed: $e');
    }
  }

  /// Clear FCM token from backend (e.g. when guest detected or on logout)
  Future<void> clearToken() async {
    try {
      await _api.post(
        '/notifications/clear-token',
        {},
        requiresAuth: true,
      );
      print('PushNotificationService: Token cleared from backend.');
    } catch (e) {
      // Ignore – user may not be logged in
    }
  }
}