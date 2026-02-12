import 'api_service.dart';

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

  Future<List<Blog>> getBlogs() async {
    try {
      final response = await _api.get('/blogs', requiresAuth: false);
      final data = response['data'];
      if (data is Map && data['blogs'] is List) {
        return (data['blogs'] as List)
            .map((b) => Blog.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
      return [];
    } catch (e) {
      print('BlogService Error: $e');
      rethrow;
    }
  }
}
