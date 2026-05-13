import 'api_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: createdAt is DateTime
          ? createdAt
          : createdAt != null
              ? DateTime.tryParse(createdAt.toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

class NotificationService {
  final ApiService _api = ApiService();

  /// Fetch notifications for the current user from the API.
  /// Returns empty list for guests or on error.
  Future<List<NotificationItem>> getMyNotifications() async {
    try {
      final response = await _api.get('/notifications/my');
      final data = response['data'];
      if (data == null || data is! List) return [];
      return data
          .map((e) =>
              NotificationItem.fromJson(Map<String, dynamic>.from(e as Map<String, dynamic>)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Mark a single notification as read on the backend.
  Future<bool> markAsRead(String id) async {
    try {
      await _api.put('/notifications/$id/read', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark all of the current user's notifications as read.
  Future<bool> markAllAsRead() async {
    try {
      await _api.put('/notifications/read-all', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a single notification (scoped to the current user).
  Future<bool> deleteOne(String id) async {
    try {
      await _api.delete('/notifications/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear all notifications for the current user on the backend.
  Future<bool> clearAll() async {
    try {
      await _api.delete('/notifications/my');
      return true;
    } catch (_) {
      return false;
    }
  }
}
