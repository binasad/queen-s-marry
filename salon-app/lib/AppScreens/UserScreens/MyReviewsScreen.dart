import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/appointment_service.dart';
import '../../utils/error_handler.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({Key? key}) : super(key: key);

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final AppointmentService _appointmentService = AppointmentService();

  List<dynamic> _myReviews = [];
  List<dynamic> _reviewableAppointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await _reviewService.getMyReviews();
      final appointments = await _appointmentService.getMyAppointments(status: 'completed');

      // Filter: completed appointments not yet reviewed
      final reviewedIds = reviews
          .map((r) => r['appointment_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      final reviewable = appointments
          .where((a) => !reviewedIds.contains(a['id']?.toString()))
          .toList();

      if (mounted) {
        setState(() {
          _myReviews = reviews;
          _reviewableAppointments = reviewable;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
        ErrorHandler.show(context, e);
      }
    }
  }

  Future<void> _submitReview(
    String appointmentId,
    String serviceName,
    int rating,
    String? comment,
  ) async {
    try {
      await _reviewService.createReview(
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  static const List<Map<String, dynamic>> _sentimentOptions = [
    {'rating': 5, 'label': 'Excellent', 'color': Colors.green},
    {'rating': 4, 'label': 'Very Good', 'color': Colors.lightGreen},
    {'rating': 3, 'label': 'Good', 'color': Colors.amber},
    {'rating': 2, 'label': 'Fair', 'color': Colors.orange},
    {'rating': 1, 'label': 'Poor', 'color': Colors.red},
  ];

  void _showReviewDialog(dynamic appointment) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Write a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['service_name'] ?? 'Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (appointment['expert_name'] != null)
                  Text(
                    'with ${appointment['expert_name']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                const SizedBox(height: 16),
                const Text('How was your experience?', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._sentimentOptions.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setDialogState(() => rating = opt['rating'] as int),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: rating == opt['rating'] ? (opt['color'] as Color).withOpacity(0.2) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rating == opt['rating'] ? opt['color'] as Color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            rating == opt['rating'] ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: rating == opt['rating'] ? opt['color'] as Color : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontWeight: rating == opt['rating'] ? FontWeight.bold : FontWeight.normal,
                              color: rating == opt['rating'] ? opt['color'] as Color : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                const Text('Comment (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitReview(
                  appointment['id'].toString(),
                  appointment['service_name'] ?? 'Service',
                  rating,
                  commentController.text.trim().isNotEmpty ? commentController.text.trim() : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD6C57),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Failed to load reviews',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_reviewableAppointments.isNotEmpty) ...[
                        const Text(
                          'Rate your experience',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap an appointment to leave a review',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ..._reviewableAppointments.map((apt) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber[100],
                                  child: Icon(Icons.rate_review, color: Colors.amber[700]),
                                ),
                                title: Text(apt['service_name'] ?? 'Service'),
                                subtitle: Text(
                                  '${apt['appointment_date'] ?? ''} • ${apt['expert_name'] ?? 'Expert'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: const Icon(Icons.add_comment),
                                onTap: () => _showReviewDialog(apt),
                              ),
                            )),
                        const Divider(height: 32),
                      ],
                      const Text(
                        'Your reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_myReviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No reviews yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete an appointment and come back to leave a review',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._myReviews.map((r) {
                              final sentiment = r['sentiment']?.toString() ?? 'Good';
                              final color = sentiment == 'Excellent' ? Colors.green : sentiment == 'Good' || sentiment == 'Very Good' ? Colors.amber[700]! : Colors.orange;
                              return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(sentiment, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                                        ),
                                        const SizedBox(width: 8),
                                        ...List.generate(
                                          5,
                                          (i) => Icon(
                                            i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                            color: Colors.amber[700],
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r['service_name'] ?? 'Service',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r['expert_name'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'with ${r['expert_name']}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                        ),
                                      ),
                                    if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          r['comment'] as String,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _formatDate(r['created_at']),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        }),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.tryParse(date.toString());
      if (d == null) return date.toString();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }
}
