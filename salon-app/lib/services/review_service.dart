import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  /// Get reviews for a service (public, no auth)
  Future<Map<String, dynamic>> getReviewsByService(String serviceId) async {
    final response = await _api.get('/reviews/by-service/$serviceId', requiresAuth: false);
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'reviews': [], 'averageRating': 0.0, 'totalCount': 0};
  }

  /// Get reviews for a course (public, no auth)
  Future<Map<String, dynamic>> getReviewsByCourse(String courseId) async {
    final response = await _api.get('/reviews/by-course/$courseId', requiresAuth: false);
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'reviews': [], 'averageRating': 0.0, 'totalCount': 0};
  }

  Future<List<dynamic>> getMyReviews() async {
    final response = await _api.get('/reviews/my', requiresAuth: true);
    if (response is! Map) return [];
    final data = response['data'];
    if (data is Map && data['reviews'] != null) {
      final list = data['reviews'];
      return list is List ? List<dynamic>.from(list) : [];
    }
    return [];
  }

  Future<Map<String, dynamic>?> getReviewByAppointment(String appointmentId) async {
    final response = await _api.get(
      '/reviews/by-appointment/$appointmentId',
      requiresAuth: true,
    );
    final data = response['data'];
    if (data is Map && data['review'] != null) {
      return Map<String, dynamic>.from(data['review'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>> createReview({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    final response = await _api.post(
      '/reviews',
      {
        'appointmentId': appointmentId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      requiresAuth: true,
    );
    final data = response['data'];
    if (data is Map && data['review'] != null) {
      return Map<String, dynamic>.from(data['review'] as Map);
    }
    return {};
  }

  Future<List<dynamic>> getMyCourseReviews() async {
    final response = await _api.get('/reviews/my-course-reviews', requiresAuth: true);
    final data = response['data'];
    if (data is Map && data['reviews'] is List) {
      return List<dynamic>.from(data['reviews'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>> createCourseReview({
    required String courseId,
    required int rating,
    String? comment,
  }) async {
    final response = await _api.post(
      '/reviews/course',
      {
        'courseId': courseId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      requiresAuth: true,
    );
    final data = response['data'];
    if (data is Map && data['review'] != null) {
      return Map<String, dynamic>.from(data['review'] as Map);
    }
    return {};
  }
}
