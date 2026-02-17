import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Manager/NotificationManager.dart';
import 'api_service.dart';
import 'storage_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'default',
    'Merry Queen Notifications',
    description: 'Appointment reminders and updates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize() async {
    // Initialize local notifications for foreground display
    await _initLocalNotifications();

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
      // iOS: Show notifications when app is in foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
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

    // 3. Listen for messages while app is open – show and store
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('PushNotificationService: Foreground message: ${message.notification!.title}');
        NotificationManager.instance.addPushNotification(
          title: message.notification!.title ?? 'Merry Queen',
          body: message.notification!.body ?? '',
        );
        _showForegroundNotification(message);
      }
    });

    // Store notifications opened from background/terminated
    final initial = await _fcm.getInitialMessage();
    if (initial?.notification != null) {
      NotificationManager.instance.addPushNotification(
        title: initial!.notification!.title ?? 'Merry Queen',
        body: initial.notification!.body ?? '',
      );
    }
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationManager.instance.addPushNotification(
          title: message.notification!.title ?? 'Merry Queen',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Create channel (required for Android 8+)
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Merry Queen',
      message.notification?.body ?? '',
      details,
    );
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
