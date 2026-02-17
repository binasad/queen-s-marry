import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/blog_service.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  static const Color brandPink = Color(0xFFFF0068);
  final BlogService _blogService = BlogService();
  bool _loading = true;
  List<Blog> _blogs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blogs = await _blogService.getBlogs(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _blogs = blogs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('SocketException')
              ? "No internet connection"
              : "We couldn't reach the stories right now";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        color: brandPink,
        onRefresh: () => _loadBlogs(forceRefresh: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Header
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFFF8F9FD).withOpacity(0.9),
              flexibleSpace: const FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  "Latest Stories",
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
                  onPressed: _loading ? null : () => _loadBlogs(forceRefresh: true),
                ),
              ],
            ),

            // Main Content Logic
            if (_loading)
              const SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CardSkeletonLoader(itemCount: 4),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (_blogs.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _BlogCard(blog: _blogs[index]),
                    childCount: _blogs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Colors.red[200]),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadBlogs(forceRefresh: true),
            style: ElevatedButton.styleFrom(backgroundColor: brandPink),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No stories today", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Blog blog;
  const _BlogCard({required this.blog});

  void _share(String title, String content) {
    Share.share("Check out this story: $title\n\n$content");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showFullBlog(context),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Hero Transition
            Hero(
              tag: 'blog-img-${blog.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: CachedImageWidget(
                  imageUrl: blog.imageUrl ?? '',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholderAsset: 'assets/logo.png',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "EDITORIAL",
                        style: TextStyle(
                          color: Color(0xFFFF0068),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _share(blog.title, blog.content),
                        icon: const Icon(Icons.ios_share, size: 18, color: Colors.grey),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    blog.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullBlog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Text(blog.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Text(blog.content, style: TextStyle(fontSize: 16, height: 1.8, color: Colors.black.withOpacity(0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}