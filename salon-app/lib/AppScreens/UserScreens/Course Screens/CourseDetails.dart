import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'CourseApplyScreen.dart';
import '../../../services/review_service.dart';
import '../../../services/offer_service.dart';
import '../../../widgets/cached_image.dart';
import '../../../services/favorites_service.dart';
import '../../../services/api_service.dart';
import '../../../providers/favorites_provider.dart';
import '../../../utils/guest_guard.dart';
import '../../../utils/haptic_feedback.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  static const Color brandPink = Color(0xFFFF0068);
  final ReviewService _reviewService = ReviewService();
  final FavoritesService _favoritesService = FavoritesService();
  final OfferService _offerService = OfferService();
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _applicableOffers = [];
  Map<String, dynamic>? _selectedOffer;
  double _avgRating = 0;
  bool _loadingReviews = true;
  bool _loadingOffers = true;
  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadFavoriteStatus();
    _loadApplicableOffers();
    final preOfferId = widget.course['_offer_id']?.toString();
    if (preOfferId != null) {
      _selectedOffer = {'id': preOfferId, 'title': widget.course['_offer_title']};
    }
  }

  Future<void> _loadApplicableOffers() async {
    try {
      final offers = await _offerService.getOffers(isActive: true);
      final courseId = widget.course['id']?.toString();
      if (!mounted) return;
      final applicable = (offers)
          .map((o) => Map<String, dynamic>.from(o as Map))
          .where((o) {
        final applyTo = o['apply_to']?.toString() ?? o['applyTo']?.toString();
        final offerCourseId = o['course_id']?.toString();
        if (applyTo == 'all_services' || applyTo == 'service') return false;
        if (applyTo == 'all_courses' || applyTo == 'all') return offerCourseId == null || offerCourseId.isEmpty || offerCourseId == courseId;
        if (applyTo == 'course') return offerCourseId == courseId;
        return offerCourseId == null || offerCourseId.isEmpty || offerCourseId == courseId;
      }).toList();
      setState(() {
        _applicableOffers = applicable;
        _loadingOffers = false;
        if (_selectedOffer == null && applicable.isNotEmpty) {
          _selectedOffer = applicable.first;
        } else if (_selectedOffer != null && _selectedOffer!['id'] != null) {
          final match = applicable.where((o) => o['id']?.toString() == _selectedOffer!['id']?.toString()).toList();
          if (match.isNotEmpty) _selectedOffer = match.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  double _getEffectivePrice() {
    final basePrice = (widget.course['_base_price'] != null)
        ? (double.tryParse(widget.course['_base_price'].toString()) ?? 0)
        : (double.tryParse(widget.course['price']?.toString() ?? '0') ?? 0);
    if (_selectedOffer != null) {
      final pct = _selectedOffer!['discount_percentage'];
      if (pct != null) {
        final val = double.tryParse(pct.toString()) ?? 0;
        return (basePrice * (1 - val / 100)).roundToDouble();
      }
    }
    return basePrice;
  }

  Future<void> _loadFavoriteStatus() async {
    final courseId = widget.course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;
    final isFav = await _favoritesService.isCourseFavorite(courseId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final courseId = widget.course['id']?.toString();
    if (courseId == null || courseId.isEmpty || _loadingFavorite) return;
    setState(() => _loadingFavorite = true);
    HapticHelper.lightImpact();
    try {
      final courseData = {
        'id': courseId,
        'title': widget.course['title']?.toString() ?? '',
        'duration': widget.course['duration']?.toString() ?? '',
        'price': widget.course['price']?.toString() ?? '0',
        'image': widget.course['image']?.toString() ?? widget.course['image_url']?.toString() ?? '',
        'image_url': widget.course['image_url']?.toString() ?? widget.course['image']?.toString() ?? '',
        'description': widget.course['description']?.toString() ?? '',
      };
      final newState = await _favoritesService.toggleCourseFavorite(
        courseId,
        courseData: courseData,
      );
      if (mounted) {
        setState(() {
          _isFavorite = newState;
          _loadingFavorite = false;
        });
        ref.invalidate(favoritesListProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFavorite = false);
        final handled = await GuestGuard.handleApiError(
          context,
          e,
          actionDescription: 'save favorites',
        );
        if (!handled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is ApiException ? e.message : 'Could not update favorite'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadReviews() async {
    final courseId = widget.course['id']?.toString();
    if (courseId == null || courseId.isEmpty) {
      setState(() => _loadingReviews = false);
      return;
    }
    try {
      final data = await _reviewService.getReviewsByCourse(courseId);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from((data['reviews'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []);
          _avgRating = (data['averageRating'] as num?)?.toDouble() ?? 0;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parallax-style Image Header
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: const BoxDecoration(),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.course['image'].toString().startsWith('http')
                          ? CachedImageWidget(
                              imageUrl: widget.course['image'],
                              width: double.infinity,
                              height: 350,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              widget.course['image'],
                              width: double.infinity,
                              height: 350,
                              fit: BoxFit.cover,
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, Colors.transparent, const Color(0xFFFBFBFD)],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course["title"], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      const SizedBox(height: 12),
                      _buildInfoBadges(),

                      if (_applicableOffers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text("Available Offers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _applicableOffers.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final o = _applicableOffers[i];
                              final isSelected = _selectedOffer?['id'] == o['id'];
                              final pct = o['discount_percentage']?.toString() ?? '';
                              return GestureDetector(
                                onTap: () => setState(() => _selectedOffer = o),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? brandPink : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_offer, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        pct.isNotEmpty ? '$pct% OFF' : (o['title'] ?? 'Offer'),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[800],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
        
                      const SizedBox(height: 32),
                      const Text("Curriculum", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _buildSubjectsWrap(),
                      const SizedBox(height: 32),
                      const Text("About Course", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(widget.course["description"], style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6), height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Glass Back Button
          _buildGlassBackButton(context),
          // Floating Favorite Button
          _buildFavoriteButton(context),
          // Floating Action Button
          _buildApplyBottomBar(context),
        ],
      ),
    );
  }

Widget _buildInfoBadges() {
    return Wrap(
      spacing: 8, // Horizontal space between badges
      runSpacing: 8, // Vertical space between lines
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _badge(Icons.timer_outlined, widget.course["duration"]),
        _badge(Icons.payments_outlined, "PKR ${_getEffectivePrice().toStringAsFixed(0)}"),
        if (_avgRating > 0) 
          _badge(Icons.star, "${_avgRating.toStringAsFixed(1)} ★"),
        if (_selectedOffer != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // Gradient for a more "Premium" offer look
              gradient: LinearGradient(
                colors: [brandPink, brandPink.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: brandPink.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _selectedOffer!['title']?.toString() ?? 'Offer',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _badge(IconData icon, dynamic label) {
    final labelStr = label?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: brandPink),
          const SizedBox(width: 8),
          Text(
            labelStr,
            style: const TextStyle(
              color: Color(0xFF1A1A1A), 
              fontWeight: FontWeight.w700, 
              fontSize: 13
            ),
          ),
        ],
      ),
    );
  }
  void _showCourseReviewDialog() {
    GuestGuard.canPerformAction(context, actionDescription: 'leave a course review').then((canProceed) {
      if (!canProceed || !mounted) return;
      int rating = 5;
      final commentController = TextEditingController();
      const options = [
        {'rating': 5, 'label': 'Excellent', 'color': Colors.green},
        {'rating': 4, 'label': 'Very Good', 'color': Colors.lightGreen},
        {'rating': 3, 'label': 'Good', 'color': Colors.amber},
        {'rating': 2, 'label': 'Fair', 'color': Colors.orange},
        {'rating': 1, 'label': 'Poor', 'color': Colors.red},
      ];
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Review ${widget.course["title"]}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How was your experience?', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => setDialogState(() => rating = opt['rating'] as int),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: rating == opt['rating'] ? (opt['color'] as Color).withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rating == opt['rating'] ? opt['color'] as Color : Colors.transparent, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(rating == opt['rating'] ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: rating == opt['rating'] ? opt['color'] as Color : Colors.grey, size: 22),
                            const SizedBox(width: 10),
                            Text(opt['label'] as String, style: TextStyle(
                              fontWeight: rating == opt['rating'] ? FontWeight.bold : FontWeight.normal,
                              color: rating == opt['rating'] ? opt['color'] as Color : Colors.black87,
                            )),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Text('Comment (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: commentController, maxLines: 3,
                    decoration: InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _reviewService.createCourseReview(
                      courseId: widget.course['id'].toString(),
                      rating: rating,
                      comment: commentController.text.trim().isNotEmpty ? commentController.text.trim() : null,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review!'), backgroundColor: Colors.green));
                      _loadReviews();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: brandPink),
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildReviewsSection() {
    if (_loadingReviews) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    if (_reviews.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
            ),
            child: Row(
              children: [
                
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        ..._reviews.take(5).map((r) {
        final sentiment = r['sentiment']?.toString() ?? 'Good';
        final color = sentiment == 'Excellent' ? Colors.green : sentiment == 'Good' || sentiment == 'Very Good' ? Colors.amber[700]! : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber[700],
                    size: 18,
                  )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(sentiment, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
              if (r['user_name'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(r['user_name'] as String, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                ),
              if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(r['comment'] as String, style: const TextStyle(fontSize: 14, height: 1.4)),
                ),
            ],
          ),
        );
      }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_comment, size: 18),
            label: const Text('Leave a Review'),
            onPressed: _showCourseReviewDialog,
            style: OutlinedButton.styleFrom(foregroundColor: brandPink, side: BorderSide(color: brandPink)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsWrap() {
    final List subjects = widget.course['subjects'] ?? [];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: subjects.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Text(s.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildGlassBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: IconButton(
              icon: _loadingFavorite
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                      size: 24,
                    ),
              onPressed: _loadingFavorite ? null : _toggleFavorite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyBottomBar(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPink,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: brandPink.withOpacity(0.5),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyFormScreen(
          course: widget.course["title"],
          courseId: widget.course["id"]?.toString(),
          offerId: _selectedOffer?['id']?.toString() ?? widget.course["_offer_id"]?.toString(),
        ))),
        child: const Text("Enroll in Academy", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}