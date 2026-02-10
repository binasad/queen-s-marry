import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

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
      
      // TODO: Call your Backend API here to save this token!
      // await api.post('/user/save-token', { token: token });
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