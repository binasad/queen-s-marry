// lib/Manager/NotificationManager.dart
import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });
}

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  NotificationManager._();

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(String message) {
    _notifications.insert(0, AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Notification',
      body: message,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void addPushNotification({required String title, required String body}) {
    _notifications.insert(0, AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
