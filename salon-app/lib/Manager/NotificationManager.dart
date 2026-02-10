// lib/Manager/NotificationManager.dart
class NotificationManager {
  static List<String> notifications = [];

  static void addNotification(String message) {
    notifications.add(message);
  }
}
