import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Cache service using Hive for fast, lightweight local storage
/// Hive is the industry standard for Flutter caching - fast, lightweight, and type-safe
class CacheService {
  static const String _servicesBoxName = 'services_cache';
  static const String _categoriesBoxName = 'categories_cache';
  static const String _coursesBoxName = 'courses_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const int _cacheExpiryHours = 24; // Cache expires after 24 hours

  static Box? _servicesBox;
  static Box? _categoriesBox;
  static Box? _coursesBox;

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    
    _servicesBox = await Hive.openBox(_servicesBoxName);
    _categoriesBox = await Hive.openBox(_categoriesBoxName);
    _coursesBox = await Hive.openBox(_coursesBoxName);
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

  /// Clear all cache
  static Future<void> clearAll() async {
    await _servicesBox?.clear();
    await _categoriesBox?.clear();
    await _coursesBox?.clear();
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

  /// Force refresh cache (clear and mark as invalid)
  static Future<void> invalidateCache() async {
    await _servicesBox?.delete(_cacheTimestampKey);
    await _categoriesBox?.delete(_cacheTimestampKey);
    await _coursesBox?.delete(_cacheTimestampKey);
  }
}
