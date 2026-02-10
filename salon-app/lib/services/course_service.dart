import 'api_service.dart';
import 'cache_service.dart';

class CourseService {
  final ApiService _api = ApiService();

  /// Get all courses with caching support
  Future<List<dynamic>> getCourses({
    String? search,
    bool? isActive,
    bool forceRefresh = false,
  }) async {
    // Clear cache if force refresh is requested
    if (forceRefresh) {
      await CacheService.clearCourses();
      print('🗑️ Courses cache cleared for force refresh');
    }

    // Only use cache if no filters are applied
    final hasFilters =
        (search != null && search.isNotEmpty) || isActive != null;

    if (!forceRefresh && !hasFilters) {
      final cachedCourses = CacheService.getCourses();
      if (cachedCourses != null && cachedCourses.isNotEmpty) {
        print('📦 Loading courses from cache');
        // Still fetch in background to update cache
        _fetchAndCacheCourses();
        return cachedCourses;
      }
    }

    // Fetch from API
    print('🌐 Loading courses from API (forceRefresh: $forceRefresh)');
    var endpoint = '/courses';
    final queryParams = <String>[];
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=$search');
    }
    if (isActive != null) {
      queryParams.add('isActive=$isActive');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _api.get(endpoint, requiresAuth: false);
    // Backend format: { success: true, data: { courses: [...], pagination: {...} } }
    final data = response['data'];
    List<dynamic> courses = const [];

    if (data is Map && data['courses'] is List) {
      courses = List<dynamic>.from(data['courses'] as List);
    } else if (data is List) {
      courses = List<dynamic>.from(data);
    }

    // Save to cache only if no filters
    if (courses.isNotEmpty && !hasFilters) {
      await CacheService.saveCourses(courses);
    }

    return courses;
  }

  /// Fetch courses in background and update cache
  Future<void> _fetchAndCacheCourses() async {
    try {
      final response = await _api.get('/courses', requiresAuth: false);
      final data = response['data'];
      List<dynamic> courses = const [];

      if (data is Map && data['courses'] is List) {
        courses = List<dynamic>.from(data['courses'] as List);
      } else if (data is List) {
        courses = List<dynamic>.from(data);
      }

      if (courses.isNotEmpty) {
        await CacheService.saveCourses(courses);
        print('✅ Courses cache updated in background');
      }
    } catch (e) {
      print('⚠️ Failed to update courses cache: $e');
    }
  }

  /// Get course by ID
  Future<Map<String, dynamic>> getCourseById(String courseId) async {
    final response = await _api.get('/courses/$courseId');
    // Backend format: { success: true, data: { course: {...} } }
    final data = response['data'];
    if (data is Map && data['course'] != null) {
      return Map<String, dynamic>.from(data['course'] as Map);
    }
    return Map<String, dynamic>.from(data as Map? ?? {});
  }
}
