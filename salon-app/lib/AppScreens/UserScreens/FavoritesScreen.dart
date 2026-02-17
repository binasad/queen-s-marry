import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/favorites_service.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/haptic_feedback.dart';
import '../../widgets/cached_image.dart';
import '../Services/servicesdetails.dart';
import 'Course Screens/CourseDetails.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesListProvider),
            color: const Color(0xFFFF6CBF),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return _FavoriteCard(
                  item: item,
                  ref: ref,
                  onTap: () {
                    HapticHelper.mediumImpact();
                    if (item['type'] == 'service' && item['service'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailedScreen(
                            service: item['service'] as Map<String, dynamic>,
                          ),
                        ),
                      );
                    } else if (item['type'] == 'course' && item['course'] != null) {
                      final courseData = Map<String, dynamic>.from(item['course'] as Map);
                      courseData['image'] = courseData['image_url'] ?? courseData['image'] ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            course: courseData,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(radius: 15)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load favorites',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(favoritesListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart icon on services and courses to add them here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final WidgetRef ref;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.item,
    required this.ref,
    required this.onTap,
  });

  @override
  ConsumerState<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<_FavoriteCard> {
  bool _removing = false;

  Future<void> _removeFavorite() async {
    if (_removing) return;
    setState(() => _removing = true);
    HapticHelper.lightImpact();
    final service = FavoritesService();
    try {
      if (widget.item['type'] == 'service') {
        await service.removeServiceFavorite(widget.item['id'].toString());
      } else {
        await service.removeCourseFavorite(widget.item['id'].toString());
      }
      if (mounted) {
        widget.ref.invalidate(favoritesListProvider);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isService = widget.item['type'] == 'service';
    final service = widget.item['service'] as Map<String, dynamic>?;
    final course = widget.item['course'] as Map<String, dynamic>?;

    String title;
    String? subtitle;
    String? price;
    String? imageUrl;

    if (isService && service != null) {
      title = service['name']?.toString() ?? 'Service';
      subtitle = '${service['duration'] ?? ''} min';
      price = 'PKR ${service['price'] ?? ''}';
      imageUrl = service['image_url']?.toString() ?? service['image']?.toString();
    } else if (course != null) {
      title = course['title']?.toString() ?? 'Course';
      subtitle = course['duration']?.toString();
      price = 'PKR ${course['price'] ?? ''}';
      imageUrl = course['image_url']?.toString() ?? course['image']?.toString();
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _removing ? null : widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedImageWidget(
                          imageUrl: imageUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 90,
                          width: 90,
                          color: Colors.grey[200],
                          child: Icon(
                            isService ? Icons.spa : Icons.menu_book,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6CBF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isService ? 'Service' : 'Course',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6CBF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (price.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6CBF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removing ? null : _removeFavorite,
                  icon: _removing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite, color: Color(0xFFFF6CBF), size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
