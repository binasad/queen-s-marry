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
}
