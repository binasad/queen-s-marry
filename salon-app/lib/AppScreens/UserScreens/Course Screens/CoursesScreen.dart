import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'CourseDetails.dart';
import '../../../providers/courses_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../services/favorites_service.dart';
import '../../../services/websocket_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../utils/guest_guard.dart';
import '../../../widgets/cached_image.dart';

// GLOBAL list for demo/legacy logic
List<Map<String, String>> appliedCandidates = [];

class CoursesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;
  final Map<String, dynamic>? activeOffer;

  const CoursesScreen({super.key, this.onRefresh, this.activeOffer});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  StreamSubscription? _coursesSubscription;
  final FavoritesService _favoritesService = FavoritesService();
  Set<String> _favoriteCourseIds = {};
  final Map<String, bool> _favoriteLoading = {};
  static const Color brandPink = Color(0xFFFF0068);
  static const Color premiumBg = Color(0xFFFBFBFD);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(coursesProvider.notifier).loadCourses(isActive: true);
    });
    _loadFavoriteIds();
    _setupWebSocket();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await _favoritesService.getFavoriteCourseIds();
      if (mounted) setState(() => _favoriteCourseIds = ids);
    } catch (_) {}
  }

  @override
  void dispose() {
    _coursesSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    final wsService = WebSocketService();
    _coursesSubscription = wsService.coursesUpdatedStream.listen((_) {
      if (mounted) ref.read(coursesProvider.notifier).loadCourses(isActive: true, forceRefresh: true);
    });
    wsService.connect();
  }

  Widget _buildOfferBanner() {
    final offer = widget.activeOffer!;
    final pct = offer['discount_percentage']?.toString();
    final title = offer['title']?.toString() ?? 'Special Offer';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandPink, brandPink.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: brandPink.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (pct != null && pct.isNotEmpty)
                  Text(
                    '$pct% off on all courses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format API data for the UI
  Map<String, dynamic> _formatCourse(Map<String, dynamic> c) {
    return {
      'id': c['id']?.toString() ?? '',
      'title': c['title']?.toString() ?? 'Elite Course',
      'duration': c['duration']?.toString() ?? 'Flexible',
      'price': c['price']?.toString() ?? '0',
      'image': c['image_url']?.toString() ?? '',
      'description': c['description']?.toString() ?? '',
      'subjects': (c['description']?.toString().contains('Subjects Included:') ?? false) 
          ? c['description'].toString().split('Subjects Included:')[1].split(',').map((e) => e.trim()).toList()
          : ['Professional Training'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesListProvider);
    final loading = ref.watch(coursesLoadingProvider);

    return Scaffold(
      backgroundColor: premiumBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              title: const Text("Our Academy", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: loading && courses.isEmpty
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : Column(
              children: [
                if (widget.activeOffer != null) _buildOfferBanner(),
                Expanded(
                  child: RefreshIndicator(
                    color: brandPink,
                    onRefresh: () async => ref.read(coursesProvider.notifier).loadCourses(isActive: true),
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(20, widget.activeOffer != null ? 16 : MediaQuery.of(context).padding.top + 80, 20, 20),
                        itemCount: courses.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final rawCourse = courses[index] as Map<String, dynamic>;
                          final courseData = _formatCourse(rawCourse);
                          final courseId = courseData['id']?.toString() ?? '';
                          final isFav = _favoriteCourseIds.contains(courseId);
                          final isLoadingFav = _favoriteLoading[courseId] ?? false;
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _PremiumCourseCard(
                                  course: courseData,
                                  isFavorite: isFav,
                                  isLoadingFavorite: isLoadingFav,
                                  onFavoriteTap: () async {
                                    if (courseId.isEmpty || isLoadingFav) return;
                                    HapticHelper.lightImpact();
                                    setState(() => _favoriteLoading[courseId] = true);
                                    try {
                                      final courseDataForFav = {
                                        'id': rawCourse['id']?.toString(),
                                        'title': rawCourse['title']?.toString(),
                                        'price': rawCourse['price']?.toString(),
                                        'duration': rawCourse['duration']?.toString(),
                                        'image_url': rawCourse['image_url']?.toString(),
                                        'image': rawCourse['image_url']?.toString(),
                                        'description': rawCourse['description']?.toString(),
                                      };
                                      final newState = await _favoritesService.toggleCourseFavorite(
                                        courseId,
                                        courseData: courseDataForFav,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _favoriteLoading[courseId] = false;
                                          if (newState) {
                                            _favoriteCourseIds.add(courseId);
                                          } else {
                                            _favoriteCourseIds.remove(courseId);
                                          }
                                        });
                                        ref.invalidate(favoritesListProvider);
                                        if (newState) {
                                          final isGuest = await _favoritesService.isGuest();
                                          if (isGuest && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Added to favorites! Sign up to sync across devices.'),
                                                backgroundColor: Color(0xFFFF0068),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() => _favoriteLoading[courseId] = false);
                                        await GuestGuard.handleApiError(
                                          context,
                                          e,
                                          actionDescription: 'save favorites',
                                        );
                                        if (!context.mounted) return;
                                        if (e is ApiException && !e.isGuestRestricted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.message),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  onTap: () {
                                    HapticHelper.mediumImpact();
                                    var courseToPass = Map<String, dynamic>.from(courseData);
                                    if (widget.activeOffer != null) {
                                      final offer = widget.activeOffer!;
                                      final basePrice = double.tryParse(courseData['price']?.toString() ?? '0') ?? 0;
                                      final pct = offer['discount_percentage'];
                                      if (pct != null) {
                                        final val = double.tryParse(pct.toString()) ?? 0;
                                        final discounted = (basePrice * (1 - val / 100)).roundToDouble();
                                        courseToPass['price'] = discounted.toStringAsFixed(0);
                                        courseToPass['_base_price'] = basePrice;
                                        courseToPass['_offer_id'] = offer['id']?.toString();
                                        courseToPass['_offer_title'] = offer['title']?.toString();
                                      }
                                    }
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(course: courseToPass),
                                    ));
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PremiumCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isFavorite;
  final bool isLoadingFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const _PremiumCourseCard({
    required this.course,
    this.isFavorite = false,
    this.isLoadingFavorite = false,
    required this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // Course hero image with 3:2 aspect ratio
                AspectRatio(
                  aspectRatio: 3 / 2,
                  child: CachedImageWidget(
                    imageUrl: course['image'] ?? '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
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
                          Expanded(
                            child: Text(
                              course['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            "PKR ${course['price']}",
                            style: const TextStyle(
                              color: Color(0xFFFF0068),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course['duration'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onFavoriteTap != null)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isLoadingFavorite ? null : onFavoriteTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: isLoadingFavorite
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: isFavorite ? const Color(0xFFFF0068) : Colors.black54,
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}