import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'service_catalog_service.dart';
import 'course_service.dart';

/// Favorites service: uses API for logged-in users, local storage for guests.
class FavoritesService {
  static const _localKeyServices = 'favorite_service_ids';
  static const _localKeyCourses = 'favorite_course_ids';

  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final CourseService _courseService = CourseService();

  Future<bool> _isGuest() async => await _storage.isGuest();

  // --- Local storage (guests) ---
  Future<List<String>> _getLocalServiceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_localKeyServices);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<String>> _getLocalCourseIds() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_localKeyCourses);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  Future<void> _saveLocalServiceIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKeyServices, jsonEncode(ids));
  }

  Future<void> _saveLocalCourseIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKeyCourses, jsonEncode(ids));
  }

  // --- API (logged-in users) ---
  Future<List<Map<String, dynamic>>> getFavoritesFromApi() async {
    final response = await _api.get('/favorites', requiresAuth: true);
    final data = response['data'];
    if (data is Map && data['favorites'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['favorites'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    return [];
  }

  Future<void> addFavoriteApi(String itemType, String itemId) async {
    await _api.post('/favorites', {
      'itemType': itemType,
      'itemId': itemId,
    }, requiresAuth: true);
  }

  Future<void> removeFavoriteApi(String itemType, String itemId) async {
    await _api.delete('/favorites/$itemType/$itemId');
  }

  Future<bool> isFavoriteApi(String itemType, String itemId) async {
    try {
      final response = await _api.get('/favorites/check/$itemType/$itemId');
      final data = response['data'];
      if (data is Map && data['isFavorite'] != null) {
        return data['isFavorite'] as bool;
      }
    } catch (_) {}
    return false;
  }

  // --- Unified API ---

  /// Get all favorites (services + courses). Works for both guest and logged-in.
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final serviceIds = await _getLocalServiceIds();
      final courseIds = await _getLocalCourseIds();
      final items = <Map<String, dynamic>>[];
      for (final id in serviceIds) {
        try {
          final s = await _catalog.getServiceById(id);
          if (s.isNotEmpty) {
            items.add({
              'type': 'service',
              'id': id,
              'service': s,
              'course': null,
            });
          }
        } catch (_) {}
      }
      for (final id in courseIds) {
        try {
          final c = await _courseService.getCourseById(id);
          if (c.isNotEmpty) {
            items.add({
              'type': 'course',
              'id': id,
              'service': null,
              'course': c,
            });
          }
        } catch (_) {}
      }
      return items;
    }
    final apiFavorites = await getFavoritesFromApi();
    final items = <Map<String, dynamic>>[];
    for (final f in apiFavorites) {
      if (f['type'] == 'service' && f['id'] != null) {
        try {
          final s = await _catalog.getServiceById(f['id'].toString());
          if (s.isNotEmpty) {
            items.add({'type': 'service', 'id': f['id'], 'service': s, 'course': null});
          }
        } catch (_) {}
      } else if (f['type'] == 'course' && f['id'] != null) {
        try {
          final c = await _courseService.getCourseById(f['id'].toString());
          if (c.isNotEmpty) {
            items.add({'type': 'course', 'id': f['id'], 'service': null, 'course': c});
          }
        } catch (_) {}
      }
    }
    return items;
  }

  /// Check if service is favorited
  Future<bool> isServiceFavorite(String serviceId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalServiceIds();
      return ids.contains(serviceId);
    }
    return isFavoriteApi('service', serviceId);
  }

  /// Check if course is favorited
  Future<bool> isCourseFavorite(String courseId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalCourseIds();
      return ids.contains(courseId);
    }
    return isFavoriteApi('course', courseId);
  }

  /// Add service to favorites
  Future<void> addServiceFavorite(String serviceId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalServiceIds();
      if (!ids.contains(serviceId)) {
        ids.add(serviceId);
        await _saveLocalServiceIds(ids);
      }
      return;
    }
    await addFavoriteApi('service', serviceId);
  }

  /// Add course to favorites
  Future<void> addCourseFavorite(String courseId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalCourseIds();
      if (!ids.contains(courseId)) {
        ids.add(courseId);
        await _saveLocalCourseIds(ids);
      }
      return;
    }
    await addFavoriteApi('course', courseId);
  }

  /// Remove service from favorites
  Future<void> removeServiceFavorite(String serviceId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalServiceIds();
      ids.remove(serviceId);
      await _saveLocalServiceIds(ids);
      return;
    }
    await removeFavoriteApi('service', serviceId);
  }

  /// Remove course from favorites
  Future<void> removeCourseFavorite(String courseId) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalCourseIds();
      ids.remove(courseId);
      await _saveLocalCourseIds(ids);
      return;
    }
    await removeFavoriteApi('course', courseId);
  }

  /// Toggle service favorite. Returns new state (true = now favorited).
  Future<bool> toggleServiceFavorite(String serviceId) async {
    final isFav = await isServiceFavorite(serviceId);
    if (isFav) {
      await removeServiceFavorite(serviceId);
      return false;
    }
    await addServiceFavorite(serviceId);
    return true;
  }

  /// Toggle course favorite. Returns new state (true = now favorited).
  Future<bool> toggleCourseFavorite(String courseId) async {
    final isFav = await isCourseFavorite(courseId);
    if (isFav) {
      await removeCourseFavorite(courseId);
      return false;
    }
    await addCourseFavorite(courseId);
    return true;
  }
}
