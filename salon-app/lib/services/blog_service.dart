import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'cache_service.dart';

class Blog {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isActive;
  final String? createdAt;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class BlogService {
  final ApiService _api = ApiService();

  Future<List<Blog>> getBlogs({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.getBlogs();
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheBlogs();
        return cached.map((b) => Blog.fromJson(Map<String, dynamic>.from(b))).toList();
      }
    } else {
      await CacheService.clearBlogs();
    }

    try {
      final response = await _api.get('/blogs', requiresAuth: false);
      final data = response['data'];
      List<Blog> blogs = [];
      if (data is Map && data['blogs'] is List) {
        blogs = (data['blogs'] as List)
            .map((b) => Blog.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
      if (blogs.isNotEmpty) {
        await CacheService.saveBlogs(blogs.map((b) => {
          'id': b.id, 'title': b.title, 'content': b.content, 'image_url': b.imageUrl,
          'is_active': b.isActive, 'created_at': b.createdAt,
        }).toList());
      }
      return blogs;
    } catch (e) {
      debugPrint('BlogService Error: $e');
      rethrow;
    }
  }

  Future<void> _fetchAndCacheBlogs() async {
    try {
      final response = await _api.get('/blogs', requiresAuth: false);
      final data = response['data'];
      if (data is Map && data['blogs'] is List) {
        final blogs = (data['blogs'] as List).map((b) => Map<String, dynamic>.from(b)).toList();
        if (blogs.isNotEmpty) await CacheService.saveBlogs(blogs);
      }
    } catch (_) {}
  }
}
