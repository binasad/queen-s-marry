import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/course_service.dart';
import '../services/cache_service.dart';

/// Courses Provider - Manages courses state
class CoursesNotifier extends StateNotifier<CoursesState> {
  final CourseService _courseService = CourseService();

  CoursesNotifier() : super(CoursesState.initial()) {
    // Load from cache first for instant UI
    _loadCoursesFromCache();
    // Then load from API
    loadCourses();
  }

  /// Load courses from cache instantly (for better UX)
  void _loadCoursesFromCache() {
    final cachedCourses = CacheService.getCourses();
    if (cachedCourses != null && cachedCourses.isNotEmpty) {
      state = state.copyWith(courses: cachedCourses);
    }
  }

  /// Load courses with caching
  Future<void> loadCourses({
    String? search,
    bool? isActive,
    bool forceRefresh = false,
  }) async {
    if (state.loading) return; // Prevent duplicate calls

    state = state.copyWith(loading: true, error: null);

    try {
      final courses = await _courseService.getCourses(
        search: search,
        isActive: isActive,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        courses: courses,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  /// Get course by ID
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      return await _courseService.getCourseById(courseId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Refresh courses (invalidate cache)
  Future<void> refresh() async {
    CacheService.clearCourses();
    await loadCourses(forceRefresh: true);
  }
}

/// Courses State
class CoursesState {
  final List<dynamic> courses;
  final bool loading;
  final String? error;

  CoursesState({
    required this.courses,
    required this.loading,
    this.error,
  });

  factory CoursesState.initial() {
    return CoursesState(
      courses: [],
      loading: false,
    );
  }

  CoursesState copyWith({
    List<dynamic>? courses,
    bool? loading,
    String? error,
  }) {
    return CoursesState(
      courses: courses ?? this.courses,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

/// Riverpod Provider for Courses
final coursesProvider = StateNotifierProvider<CoursesNotifier, CoursesState>((ref) {
  return CoursesNotifier();
});

/// Convenience providers
final coursesListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(coursesProvider).courses;
});

final coursesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(coursesProvider).loading;
});

final coursesErrorProvider = Provider<String?>((ref) {
  return ref.watch(coursesProvider).error;
});
