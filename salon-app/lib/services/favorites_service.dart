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
  static const _localKeyServicesData = 'favorite_services_data';
  static const _localKeyCoursesData = 'favorite_courses_data';

  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final CourseService _courseService = CourseService();

  /// Guest = no auth token and explicitly in guest mode. Logged-in users always use API.
  Future<bool> _isGuest() async {
    final token = await _api.getAccessToken();
    if (token != null && token.isNotEmpty) return false; // Has token = logged in
    return await _storage.isGuest();
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // --- Local storage (guests) ---
  Future<List<String>> _getLocalServiceIds() async {
    final prefs = await _prefs;
    final json = prefs.getString(_localKeyServices);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<String>> _getLocalCourseIds() async {
    final prefs = await _prefs;
    final json = prefs.getString(_localKeyCourses);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  Future<Map<String, Map<String, dynamic>>> _getLocalServicesData() async {
    final prefs = await _prefs;
    final json = prefs.getString(_localKeyServicesData);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>?;
      if (map == null) return {};
      return map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getLocalCoursesData() async {
    final prefs = await _prefs;
    final json = prefs.getString(_localKeyCoursesData);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>?;
      if (map == null) return {};
      return map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalServiceIds(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setString(_localKeyServices, jsonEncode(ids));
  }

  Future<void> _saveLocalCourseIds(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setString(_localKeyCourses, jsonEncode(ids));
  }

  Future<void> _saveLocalServicesData(Map<String, Map<String, dynamic>> data) async {
    final prefs = await _prefs;
    await prefs.setString(_localKeyServicesData, jsonEncode(data));
  }

  Future<void> _saveLocalCoursesData(Map<String, Map<String, dynamic>> data) async {
    final prefs = await _prefs;
    await prefs.setString(_localKeyCoursesData, jsonEncode(data));
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
      // Load all local data in parallel
      final results = await Future.wait([
        _getLocalServiceIds(),
        _getLocalCourseIds(),
        _getLocalServicesData(),
        _getLocalCoursesData(),
      ]);
      final serviceIds = results[0] as List<String>;
      final courseIds = results[1] as List<String>;
      final servicesData = results[2] as Map<String, Map<String, dynamic>>;
      final coursesData = results[3] as Map<String, Map<String, dynamic>>;
      final items = <Map<String, dynamic>>[];

      // Collect IDs that need API fetch (cache miss)
      final serviceIdsToFetch = <String>[];
      final courseIdsToFetch = <String>[];

      for (final id in serviceIds) {
        final s = servicesData[id];
        if (s != null && s.isNotEmpty) {
          items.add({'type': 'service', 'id': id, 'service': s, 'course': null});
        } else {
          serviceIdsToFetch.add(id);
        }
      }
      for (final id in courseIds) {
        final c = coursesData[id];
        if (c != null && c.isNotEmpty) {
          items.add({'type': 'course', 'id': id, 'service': null, 'course': c});
        } else {
          courseIdsToFetch.add(id);
        }
      }

      // Fetch missing items in parallel (not sequential)
      final serviceFutures = serviceIdsToFetch.map((id) async {
        try {
          return await _catalog.getServiceById(id);
        } catch (_) {
          return <String, dynamic>{};
        }
      });
      final courseFutures = courseIdsToFetch.map((id) async {
        try {
          return await _courseService.getCourseById(id);
        } catch (_) {
          return <String, dynamic>{};
        }
      });
      final fetchedServices = await Future.wait(serviceFutures);
      final fetchedCourses = await Future.wait(courseFutures);

      for (var i = 0; i < serviceIdsToFetch.length; i++) {
        final fetched = fetchedServices[i];
        if (fetched.isNotEmpty) {
          items.add({'type': 'service', 'id': serviceIdsToFetch[i], 'service': fetched, 'course': null});
        }
      }
      for (var i = 0; i < courseIdsToFetch.length; i++) {
        final fetched = fetchedCourses[i];
        if (fetched.isNotEmpty) {
          items.add({'type': 'course', 'id': courseIdsToFetch[i], 'service': null, 'course': fetched});
        }
      }
      return items;
    }
    final apiFavorites = await getFavoritesFromApi();
    final items = <Map<String, dynamic>>[];
    for (final f in apiFavorites) {
      // Backend returns itemType and itemId
      final itemType = f['itemType']?.toString() ?? f['type']?.toString();
      final itemId = (f['itemId'] ?? f['id'])?.toString() ?? '';
      if (itemType == 'service' && itemId.isNotEmpty) {
        try {
          final s = await _catalog.getServiceById(itemId);
          if (s.isNotEmpty) {
            items.add({'type': 'service', 'id': itemId, 'service': s, 'course': null});
          }
        } catch (_) {}
      } else if (itemType == 'course' && itemId.isNotEmpty) {
        try {
          final c = await _courseService.getCourseById(itemId);
          if (c.isNotEmpty) {
            items.add({'type': 'course', 'id': itemId, 'service': null, 'course': c});
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

  /// Add service to favorites. For guests, pass [serviceData] to store locally (no API).
  Future<void> addServiceFavorite(String serviceId, {Map<String, dynamic>? serviceData}) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalServiceIds();
      if (!ids.contains(serviceId)) {
        ids.add(serviceId);
        await _saveLocalServiceIds(ids);
        if (serviceData != null && serviceData.isNotEmpty) {
          final data = await _getLocalServicesData();
          data[serviceId] = serviceData;
          await _saveLocalServicesData(data);
        }
      }
      return;
    }
    await addFavoriteApi('service', serviceId);
  }

  /// Add course to favorites. For guests, pass [courseData] to store locally (no API).
  Future<void> addCourseFavorite(String courseId, {Map<String, dynamic>? courseData}) async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) {
      final ids = await _getLocalCourseIds();
      if (!ids.contains(courseId)) {
        ids.add(courseId);
        await _saveLocalCourseIds(ids);
        if (courseData != null && courseData.isNotEmpty) {
          final data = await _getLocalCoursesData();
          data[courseId] = courseData;
          await _saveLocalCoursesData(data);
        }
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
      final data = await _getLocalServicesData();
      data.remove(serviceId);
      await _saveLocalServicesData(data);
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
      final data = await _getLocalCoursesData();
      data.remove(courseId);
      await _saveLocalCoursesData(data);
      return;
    }
    await removeFavoriteApi('course', courseId);
  }

  /// Toggle service favorite. Returns new state (true = now favorited).
  /// For guests, pass [serviceData] when adding so it's stored locally.
  Future<bool> toggleServiceFavorite(String serviceId, {Map<String, dynamic>? serviceData}) async {
    final isFav = await isServiceFavorite(serviceId);
    if (isFav) {
      await removeServiceFavorite(serviceId);
      return false;
    }
    await addServiceFavorite(serviceId, serviceData: serviceData);
    return true;
  }

  /// Toggle course favorite. Returns new state (true = now favorited).
  /// For guests, pass [courseData] when adding so it's stored locally.
  Future<bool> toggleCourseFavorite(String courseId, {Map<String, dynamic>? courseData}) async {
    final isFav = await isCourseFavorite(courseId);
    if (isFav) {
      await removeCourseFavorite(courseId);
      return false;
    }
    await addCourseFavorite(courseId, courseData: courseData);
    return true;
  }

  /// Migrate guest favorites to API when user logs in. Runs in background.
  Future<void> migrateGuestFavoritesToApi() async {
    final isGuestUser = await _isGuest();
    if (isGuestUser) return; // Still guest, nothing to migrate

    final serviceIds = await _getLocalServiceIds();
    final courseIds = await _getLocalCourseIds();
    if (serviceIds.isEmpty && courseIds.isEmpty) return;

    try {
      for (final id in serviceIds) {
        try {
          await addFavoriteApi('service', id);
        } catch (_) {}
      }
      for (final id in courseIds) {
        try {
          await addFavoriteApi('course', id);
        } catch (_) {}
      }
      // Clear local guest data after successful migration
      await _saveLocalServiceIds([]);
      await _saveLocalCourseIds([]);
      await _saveLocalServicesData({});
      await _saveLocalCoursesData({});
    } catch (_) {}
  }
}
