import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Cache service using Hive for fast, lightweight local storage
/// Hive is the industry standard for Flutter caching - fast, lightweight, and type-safe
class CacheService {
  static const String _servicesBoxName = 'services_cache';
  static const String _categoriesBoxName = 'categories_cache';
  static const String _coursesBoxName = 'courses_cache';
  static const String _offersBoxName = 'offers_cache';
  static const String _expertsBoxName = 'experts_cache';
  static const String _blogsBoxName = 'blogs_cache';
  static const String _servicesByCatBoxName = 'services_by_category_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const int _cacheExpiryHours = 24; // Cache expires after 24 hours

  static Box? _servicesBox;
  static Box? _categoriesBox;
  static Box? _coursesBox;
  static Box? _offersBox;
  static Box? _expertsBox;
  static Box? _blogsBox;
  static Box? _servicesByCatBox;

  /// Initialize Hive and open boxes (parallel for faster startup)
  static Future<void> init() async {
    await Hive.initFlutter();
    final boxes = await Future.wait([
      Hive.openBox(_servicesBoxName),
      Hive.openBox(_categoriesBoxName),
      Hive.openBox(_coursesBoxName),
      Hive.openBox(_offersBoxName),
      Hive.openBox(_expertsBoxName),
      Hive.openBox(_blogsBoxName),
      Hive.openBox(_servicesByCatBoxName),
    ]);
    _servicesBox = boxes[0];
    _categoriesBox = boxes[1];
    _coursesBox = boxes[2];
    _offersBox = boxes[3];
    _expertsBox = boxes[4];
    _blogsBox = boxes[5];
    _servicesByCatBox = boxes[6];
  }

  /// Check if cache is valid (not expired)
  static bool _isCacheValid(Box box) {
    final timestamp = box.get(_cacheTimestampKey) as int?;
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expiryTime = cacheTime.add(Duration(hours: _cacheExpiryHours));
    return DateTime.now().isBefore(expiryTime);
  }

  /// Save services to cache
  static Future<void> saveServices(List<dynamic> services) async {
    if (_servicesBox == null) await init();
    
    final servicesJson = services.map((s) => jsonEncode(s)).toList();
    await _servicesBox!.put('services', servicesJson);
    await _servicesBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get services from cache
  static List<dynamic>? getServices() {
    if (_servicesBox == null) return null;
    if (!_isCacheValid(_servicesBox!)) return null;
    
    final servicesJson = _servicesBox!.get('services') as List?;
    if (servicesJson == null) return null;
    
    return servicesJson.map((s) => jsonDecode(s as String)).toList();
  }

  /// Save categories to cache
  static Future<void> saveCategories(List<dynamic> categories) async {
    if (_categoriesBox == null) await init();
    
    final categoriesJson = categories.map((c) => jsonEncode(c)).toList();
    await _categoriesBox!.put('categories', categoriesJson);
    await _categoriesBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get categories from cache
  static List<dynamic>? getCategories() {
    if (_categoriesBox == null) return null;
    if (!_isCacheValid(_categoriesBox!)) return null;
    
    final categoriesJson = _categoriesBox!.get('categories') as List?;
    if (categoriesJson == null) return null;
    
    return categoriesJson.map((c) => jsonDecode(c as String)).toList();
  }

  /// Save courses to cache
  static Future<void> saveCourses(List<dynamic> courses) async {
    if (_coursesBox == null) await init();
    
    final coursesJson = courses.map((c) => jsonEncode(c)).toList();
    await _coursesBox!.put('courses', coursesJson);
    await _coursesBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get courses from cache
  static List<dynamic>? getCourses() {
    if (_coursesBox == null) return null;
    if (!_isCacheValid(_coursesBox!)) return null;
    
    final coursesJson = _coursesBox!.get('courses') as List?;
    if (coursesJson == null) return null;
    
    return coursesJson.map((c) => jsonDecode(c as String)).toList();
  }

  /// Save blogs to cache
  static Future<void> saveBlogs(List<dynamic> blogs) async {
    if (_blogsBox == null) await init();
    final blogsJson = blogs.map((b) => jsonEncode(b)).toList();
    await _blogsBox!.put('blogs', blogsJson);
    await _blogsBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get blogs from cache
  static List<dynamic>? getBlogs() {
    if (_blogsBox == null) return null;
    if (!_isCacheValid(_blogsBox!)) return null;
    final blogsJson = _blogsBox!.get('blogs') as List?;
    if (blogsJson == null) return null;
    return blogsJson.map((b) => jsonDecode(b as String)).toList();
  }

  /// Save services by category (keyed by categoryId)
  static Future<void> saveServicesByCategory(String categoryId, List<dynamic> services) async {
    if (_servicesByCatBox == null) await init();
    final key = 'cat_$categoryId';
    final data = {'data': services.map((s) => jsonEncode(s)).toList(), 'ts': DateTime.now().millisecondsSinceEpoch};
    await _servicesByCatBox!.put(key, jsonEncode(data));
  }

  /// Get services by category (valid for 24h)
  static List<dynamic>? getServicesByCategory(String categoryId) {
    if (_servicesByCatBox == null) return null;
    final key = 'cat_$categoryId';
    final raw = _servicesByCatBox!.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map;
      final ts = map['ts'] as int?;
      if (ts == null) return null;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cacheTime).inHours >= _cacheExpiryHours) return null;
      final data = map['data'] as List?;
      if (data == null) return null;
      return data.map((s) => jsonDecode(s as String)).toList();
    } catch (_) { return null; }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    await _servicesBox?.clear();
    await _categoriesBox?.clear();
    await _coursesBox?.clear();
    await _offersBox?.clear();
    await _expertsBox?.clear();
    await _blogsBox?.clear();
    await _servicesByCatBox?.clear();
  }

  /// Save offers to cache
  static Future<void> saveOffers(List<dynamic> offers) async {
    if (_offersBox == null) await init();
    final offersJson = offers.map((o) => jsonEncode(o)).toList();
    await _offersBox!.put('offers', offersJson);
    await _offersBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get offers from cache
  static List<dynamic>? getOffers() {
    if (_offersBox == null) return null;
    if (!_isCacheValid(_offersBox!)) return null;
    final offersJson = _offersBox!.get('offers') as List?;
    if (offersJson == null) return null;
    return offersJson.map((o) => jsonDecode(o as String)).toList();
  }

  /// Save experts to cache
  static Future<void> saveExperts(List<dynamic> experts) async {
    if (_expertsBox == null) await init();
    final expertsJson = experts.map((e) => jsonEncode(e)).toList();
    await _expertsBox!.put('experts', expertsJson);
    await _expertsBox!.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get experts from cache
  static List<dynamic>? getExperts() {
    if (_expertsBox == null) return null;
    if (!_isCacheValid(_expertsBox!)) return null;
    final expertsJson = _expertsBox!.get('experts') as List?;
    if (expertsJson == null) return null;
    return expertsJson.map((e) => jsonDecode(e as String)).toList();
  }

  /// Clear specific cache
  static Future<void> clearServices() async {
    await _servicesBox?.clear();
  }

  static Future<void> clearCategories() async {
    await _categoriesBox?.clear();
  }

  static Future<void> clearCourses() async {
    await _coursesBox?.clear();
  }

  static Future<void> clearOffers() async {
    await _offersBox?.clear();
  }

  static Future<void> clearExperts() async {
    await _expertsBox?.clear();
  }

  static Future<void> clearBlogs() async {
    await _blogsBox?.clear();
  }

  static Future<void> clearServicesByCategory(String? categoryId) async {
    if (categoryId != null) {
      await _servicesByCatBox?.delete('cat_$categoryId');
    } else {
      await _servicesByCatBox?.clear();
    }
  }

  /// Force refresh cache (clear and mark as invalid)
  static Future<void> invalidateCache() async {
    await _servicesBox?.delete(_cacheTimestampKey);
    await _categoriesBox?.delete(_cacheTimestampKey);
    await _coursesBox?.delete(_cacheTimestampKey);
    await _offersBox?.delete(_cacheTimestampKey);
    await _expertsBox?.delete(_cacheTimestampKey);
    await _blogsBox?.delete(_cacheTimestampKey);
    await _servicesByCatBox?.clear();
  }
}
