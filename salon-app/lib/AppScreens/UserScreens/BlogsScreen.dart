import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import '../../services/blog_service.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final BlogService _blogService = BlogService();
  bool _loading = true;
  List<Blog> _blogs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blogs = await _blogService.getBlogs();
      if (mounted) {
        setState(() {
          _blogs = blogs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().split('\n').first;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Blogs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadBlogs,
          ),
        ],
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.99,
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          RefreshIndicator(
            onRefresh: _loadBlogs,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadBlogs,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _blogs.isEmpty
                        ? const Center(
                            child: Text(
                              "No blogs yet.\nCheck back soon!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _blogs.length,
                            itemBuilder: (context, index) {
                              return _BlogCard(blog: _blogs[index], onRefresh: _loadBlogs);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onRefresh;

  const _BlogCard({required this.blog, required this.onRefresh});

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  void _showFullBlog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedImageWidget(
                      imageUrl: blog.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                blog.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (blog.createdAt != null && blog.createdAt!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDate(blog.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                blog.content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showFullBlog(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
            CachedImageWidget(
              imageUrl: blog.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (blog.createdAt != null && blog.createdAt!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(blog.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  blog.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Tap to read more",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
