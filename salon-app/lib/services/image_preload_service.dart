import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'api_service.dart';
import 'cache_service.dart';

/// Preloads images to local disk cache at app startup.
/// Uses the same DefaultCacheManager as cached_network_image, so images
/// will load instantly when displayed later.
class ImagePreloadService {
  /// Preload all courses + services; cap others (offers, blogs, experts) to avoid excessive preload
  static const int _maxOtherImages = 50;
  static const int _concurrency = 6;

  /// Collect image URLs from cached data, grouped by source
  static ({List<String> coursesAndServices, List<String> others}) _collectUrlsFromCache() {
    final courseSvc = <String>{};
    final others = <String>{};

    void addUrl(dynamic url, {required bool isCourseOrService}) {
      final s = url?.toString() ?? '';
      if (s.startsWith('http') && s.length > 10) {
        if (isCourseOrService) {
          courseSvc.add(s);
        } else {
          others.add(s);
        }
      }
    }

    for (final c in CacheService.getCategories() ?? []) {
      if (c is Map) addUrl(c['image_url'], isCourseOrService: true);
    }
    for (final s in CacheService.getServices() ?? []) {
      if (s is Map) addUrl(s['image_url'], isCourseOrService: true);
    }
    for (final c in CacheService.getCourses() ?? []) {
      if (c is Map) addUrl(c['image_url'], isCourseOrService: true);
    }
    for (final o in CacheService.getOffers() ?? []) {
      if (o is Map) addUrl(o['image_url'], isCourseOrService: false);
    }
    for (final b in CacheService.getBlogs() ?? []) {
      if (b is Map) addUrl(b['image_url'], isCourseOrService: false);
    }
    for (final e in CacheService.getExperts() ?? []) {
      if (e is Map) addUrl(e['profile_image_url'], isCourseOrService: false);
    }

    return (
      coursesAndServices: courseSvc.toList(),
      others: others.take(_maxOtherImages).toList(),
    );
  }

  /// Collect image URLs from API response data
  static Set<String> _collectUrlsFromData(List<dynamic> items, String key) {
    final urls = <String>{};
    for (final item in items) {
      if (item is Map) {
        final url = item[key]?.toString();
        if (url != null && url.startsWith('http') && url.length > 10) {
          urls.add(url);
        }
      }
    }
    return urls;
  }

  /// Fetch data from API and collect image URLs by source
  static Future<({List<String> coursesAndServices, List<String> others})> _fetchUrlsFromApi() async {
    final courseSvc = <String>{};
    final others = <String>{};
    final api = ApiService();

    try {
      // Categories (used with services)
      final catRes = await api.get('/categories', requiresAuth: false);
      final catData = catRes['data'];
      List<dynamic> cats = [];
      if (catData is List) cats = catData;
      if (catData is Map && catData['categories'] is List) cats = catData['categories'] as List;
      courseSvc.addAll(_collectUrlsFromData(cats, 'image_url'));

      // Services (fetch all - backend allows up to 500 per request)
      final svcRes = await api.get('/services?limit=500&isActive=true', requiresAuth: false);
      final svcData = svcRes['data'];
      List<dynamic> svcs = [];
      if (svcData is Map && svcData['services'] is List) svcs = svcData['services'] as List;
      courseSvc.addAll(_collectUrlsFromData(svcs, 'image_url'));

      // Courses (fetch all)
      final courseRes = await api.get('/courses?isActive=true&limit=200', requiresAuth: false);
      final courseData = courseRes['data'];
      List<dynamic> courses = [];
      if (courseData is List) courses = courseData;
      if (courseData is Map && courseData['courses'] is List) courses = courseData['courses'] as List;
      courseSvc.addAll(_collectUrlsFromData(courses, 'image_url'));

      // Offers
      final offRes = await api.get('/offers?isActive=true', requiresAuth: false);
      final offData = offRes['data'];
      List<dynamic> offs = [];
      if (offData is Map && offData['offers'] is List) offs = offData['offers'] as List;
      others.addAll(_collectUrlsFromData(offs, 'image_url'));

      // Blogs
      try {
        final blogRes = await api.get('/blogs', requiresAuth: false);
        final blogData = blogRes['data'];
        List<dynamic> blogs = [];
        if (blogData is List) blogs = blogData;
        if (blogData is Map && blogData['blogs'] is List) blogs = blogData['blogs'] as List;
        others.addAll(_collectUrlsFromData(blogs, 'image_url'));
      } catch (_) {}

      // Experts
      try {
        final expRes = await api.get('/experts', requiresAuth: false);
        final expData = expRes['data'];
        List<dynamic> experts = [];
        if (expData is List) experts = expData;
        if (expData is Map && expData['experts'] is List) experts = expData['experts'] as List;
        others.addAll(_collectUrlsFromData(experts, 'profile_image_url'));
      } catch (_) {}
    } catch (e) {
      debugPrint('ImagePreloadService: API fetch failed: $e');
    }

    return (
      coursesAndServices: courseSvc.toList(),
      others: others.take(_maxOtherImages).toList(),
    );
  }

  /// Download a single image to cache (uses same cache as CachedNetworkImage)
  static Future<void> _downloadToCache(String url) async {
    try {
      await DefaultCacheManager().downloadFile(url);
    } catch (_) {}
  }

  /// Preload images in background. Call at app startup - does not block.
  /// Preloads ALL course and service images; limits others (offers, blogs, experts).
  static void preloadImagesInBackground() {
    Future(() async {
      var cached = _collectUrlsFromCache();

      // If cache is empty, fetch from API
      if (cached.coursesAndServices.isEmpty && cached.others.isEmpty) {
        cached = await _fetchUrlsFromApi();
      }

      final toPreload = [...cached.coursesAndServices, ...cached.others];
      if (toPreload.isEmpty) return;

      debugPrint(
          'ImagePreloadService: Preloading ${toPreload.length} images (${cached.coursesAndServices.length} courses/services)');

      // Download in batches to limit concurrency
      for (var i = 0; i < toPreload.length; i += _concurrency) {
        final batch = toPreload.skip(i).take(_concurrency).toList();
        await Future.wait(batch.map(_downloadToCache));
      }

      debugPrint('ImagePreloadService: Preload complete');
    });
  }
}
