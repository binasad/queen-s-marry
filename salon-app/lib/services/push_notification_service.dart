import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  Future<void> initialize() async {
    // 1. Request Permission (Required for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the Token (Address)
      String? token = await _fcm.getToken();
      print("🔥 My Device Token: $token");

      // Save token to backend when user is logged in
      if (token != null && token.isNotEmpty) {
        try {
          await _api.post(
            '/notifications/save-token',
            {'fcmToken': token},
            requiresAuth: true,
          );
          print("✅ FCM token saved to backend");
        } catch (e) {
          print("⚠️ Could not save FCM token (user may not be logged in): $e");
        }
      }
    }

    // 3. Listen for messages while app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message: ${message.notification!.title}');
        // Show a local snackbar or dialog here
      }
    });
  }
}