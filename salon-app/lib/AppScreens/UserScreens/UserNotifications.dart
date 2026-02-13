import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Manager/NotificationManager.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _apiNotifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _notificationService.getMyNotifications();
      if (mounted) {
        setState(() {
          _apiNotifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<_DisplayNotification> _getMergedNotifications() {
    final apiItems = _apiNotifications
        .map((n) => _DisplayNotification(
              id: 'api_${n.id}',
              title: n.title,
              body: n.message,
              createdAt: n.createdAt,
            ))
        .toList();
    final memoryItems = NotificationManager.instance.notifications
        .map((n) => _DisplayNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              createdAt: n.createdAt,
            ))
        .toList();
    // Combine: API first (persistent), then in-memory (real-time session)
    // Dedupe by approximate match - prefer API version
    final seen = <String>{};
    final merged = <_DisplayNotification>[];
    for (final n in apiItems) {
      merged.add(n);
      seen.add('${n.title}|${n.body}|${n.createdAt.millisecondsSinceEpoch}');
    }
    for (final n in memoryItems) {
      final key = '${n.title}|${n.body}|${n.createdAt.millisecondsSinceEpoch}';
      if (!seen.contains(key)) {
        merged.add(n);
        seen.add(key);
      }
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  void _onClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all'),
        content: const Text(
          'Clear all notifications? This clears only in-app notifications from this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              NotificationManager.instance.clearAll();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6CBF),
                Color(0xFFFFC371),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: NotificationManager.instance,
            builder: (context, _) {
              final merged = _getMergedNotifications();
              if (merged.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _onClearAll,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF),
              Color(0xFFFFC371),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
            color: Colors.white,
          ),
          child: ListenableBuilder(
            listenable: NotificationManager.instance,
            builder: (context, _) {
              if (_loading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (_error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load notifications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final notifications = _getMergedNotifications();
              if (notifications.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "No notifications yet.\n\nYou'll see appointment updates and reminders here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 25, bottom: 24),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFAD0C4),
                              Color(0xFFFDCBF1),
                              Color(0xFFD1FDFF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.notifications,
                              color: Colors.black),
                          title: Text(
                            n.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, h:mm a').format(n.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisplayNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  _DisplayNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });
}
