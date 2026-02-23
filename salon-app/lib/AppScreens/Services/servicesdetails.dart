import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../UserScreens/AppointmentBooking.dart';

import '../../services/service_catalog_service.dart';
import '../../services/offer_service.dart';
import '../../services/review_service.dart';
import '../../services/favorites_service.dart';
import '../../services/api_service.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/guest_guard.dart';
import '../../utils/haptic_feedback.dart';
import '../../widgets/cached_image.dart';

class ServiceDetailedScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> service;
  final List<Map<String, dynamic>>? allServices;
  final Map<String, dynamic>? activeOffer;
  final String? offerId;
  final double? offerDiscountedPrice;

  const ServiceDetailedScreen({
    super.key,
    required this.service,
    this.allServices,
    this.activeOffer,
    this.offerId,
    this.offerDiscountedPrice,
  });



  @override
  ConsumerState<ServiceDetailedScreen> createState() => _ServiceDetailedScreenState();
}

class _ServiceDetailedScreenState extends ConsumerState<ServiceDetailedScreen> {
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final OfferService _offerService = OfferService();
  final ReviewService _reviewService = ReviewService();
  final FavoritesService _favoritesService = FavoritesService();
  List<Map<String, dynamic>> _relatedServices = [];

  List<Map<String, dynamic>> _reviews = [];

  double _avgRating = 0;

  bool _loadingRelated = true;
  bool _loadingReviews = true;
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  List<Map<String, dynamic>> _applicableOffers = [];
  Map<String, dynamic>? _selectedOffer;

  @override
  void initState() {
    super.initState();
    _loadRelatedServices();
    _loadReviews();
    _loadFavoriteStatus();
    _loadApplicableOffers();
    if (widget.activeOffer != null) _selectedOffer = widget.activeOffer;
  }

  Future<void> _loadApplicableOffers() async {
    try {
      final offers = await _offerService.getOffers(isActive: true);
      final serviceId = widget.service['id']?.toString();
      if (!mounted) return;
      final applicable = offers
          .map((o) => Map<String, dynamic>.from(o as Map))
          .where((o) {
        final applyTo = o['apply_to']?.toString() ?? o['applyTo']?.toString();
        final offerSvcId = o['service_id']?.toString();
        if (applyTo == 'all_courses' || applyTo == 'course') return false;
        if (applyTo == 'all_services' || applyTo == 'all') return offerSvcId == null || offerSvcId.isEmpty || offerSvcId == serviceId;
        if (applyTo == 'service') return offerSvcId == serviceId;
        return offerSvcId == null || offerSvcId.isEmpty || offerSvcId == serviceId;
      }).toList();
      setState(() {
        _applicableOffers = applicable;
        if (_selectedOffer == null && applicable.isNotEmpty && widget.activeOffer == null) {
          _selectedOffer = applicable.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final serviceId = widget.service['id']?.toString();
    if (serviceId == null || serviceId.isEmpty) return;
    final isFav = await _favoritesService.isServiceFavorite(serviceId);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final serviceId = widget.service['id']?.toString();
    if (serviceId == null || serviceId.isEmpty || _loadingFavorite) return;
    setState(() => _loadingFavorite = true);
    HapticHelper.lightImpact();
    try {
      final newState = await _favoritesService.toggleServiceFavorite(
        serviceId,
        serviceData: Map<String, dynamic>.from(widget.service),
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

    final serviceId = widget.service['id']?.toString();

    if (serviceId == null || serviceId.isEmpty) {

      setState(() => _loadingReviews = false);

      return;

    }

    try {

      final data = await _reviewService.getReviewsByService(serviceId);

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



  Widget _buildServiceImage(Map<String, dynamic> s, {double? width, double? height}) {
    final url = s['image_url']?.toString() ?? s['image']?.toString() ?? '';
    if (url.isEmpty) return Image.asset('assets/FeatherCutting.png', width: width, height: height, fit: BoxFit.cover);
    if (url.startsWith('http')) return CachedImageWidget(imageUrl: url, width: width, height: height, fit: BoxFit.cover);
    return Image.asset(url, width: width, height: height, fit: BoxFit.cover);
  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFBFBFD),

      extendBodyBehindAppBar: true,

      body: Stack(

        children: [

          CustomScrollView(

            physics: const BouncingScrollPhysics(),

            slivers: [

              _buildAppBar(),

              SliverToBoxAdapter(

                child: Container(

                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const SizedBox(height: 20),

                      _buildHeaderSection(),

                      const SizedBox(height: 24),

                      _buildStatsRow(),

                      const SizedBox(height: 32),

                      if (_applicableOffers.isNotEmpty) ...[
                        const Text("Available Offers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            cacheExtent: 200,
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
                                    color: isSelected ? const Color(0xFFFF6CBF) : Colors.grey[100],
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
                        const SizedBox(height: 24),
                      ],

                      const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),

                      const SizedBox(height: 12),

                      Text(

                        widget.service['description']?.toString() ?? "A premium wellness experience.",

                        style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6), height: 1.6),

                      ),

                      const SizedBox(height: 32),

                      const Text("Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),

                      const SizedBox(height: 12),

                      _buildReviewsSection(),

                      const SizedBox(height: 40),

                      const Text("You may also like", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),

                      const SizedBox(height: 16),

                      _buildRelatedCarousel(),

                    ],

                  ),

                ),

              ),

            ],

          ),

          // Floating Swipe-to-Book Bar

          _buildSwipeToBookBar(),

        ],

      ),

    );

  }



  Widget _buildAppBar() {

    return SliverAppBar(

      expandedHeight: 400,

      backgroundColor: Colors.transparent,

      elevation: 0,

      leading: Padding(

        padding: const EdgeInsets.all(8.0),

        child: CircleAvatar(

          backgroundColor: Colors.white.withOpacity(0.9),

          child: IconButton(

            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),

            onPressed: () => Navigator.pop(context),

          ),

        ),

      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: _loadingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? const Color(0xFFFF6CBF) : Colors.black54,
                      size: 24,
                    ),
              onPressed: _loadingFavorite ? null : _toggleFavorite,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(

        background: Stack(

          fit: StackFit.expand,

          children: [

            _buildServiceImage(widget.service),

            const DecoratedBox(

              decoration: BoxDecoration(

                gradient: LinearGradient(

                  begin: Alignment.topCenter,

                  end: Alignment.bottomCenter,

                  colors: [Colors.black26, Colors.transparent, Colors.white],

                  stops: [0.0, 0.4, 1.0],

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.activeOffer != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6CBF),
                  const Color(0xFFFF6CBF).withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.activeOffer!['title']?.toString() ?? 'Offer applied',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Text(
          widget.service['name']?.toString() ?? '',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text("${widget.service['duration'] ?? '45 min'}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }



  double _getEffectivePrice() {
    // Use _base_price when present (from offer flow) to avoid double-discounting
    final basePrice = (widget.service['_base_price'] != null)
        ? (double.tryParse(widget.service['_base_price'].toString()) ?? 0)
        : (double.tryParse(widget.service['price']?.toString() ?? '0') ?? 0);
    final offer = _selectedOffer ?? widget.activeOffer;
    if (offer != null) {
      final pct = offer['discount_percentage'];
      if (pct != null) {
        final val = double.tryParse(pct.toString()) ?? 0;
        return (basePrice * (1 - val / 100)).roundToDouble();
      }
    }
    return basePrice;
  }

  Widget _buildStatsRow() {
    final ratingStr = _avgRating > 0 ? '$_avgRating ★' : '—';
    final countStr = _reviews.isNotEmpty ? '${_reviews.length}+' : '0';
    final effectivePrice = _getEffectivePrice();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: "Rating", value: ratingStr),
          _StatItem(label: "Reviews", value: countStr),
          _StatItem(label: "Price", value: "PKR ${effectivePrice.toStringAsFixed(0)}"),
        ],
      ),
    );
  }



  Widget _buildReviewsSection() {

    if (_loadingReviews) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator()));

    if (_reviews.isEmpty) {

      return Container(

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],

        ),

        child: Row(

          children: [

            Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey[400]),

            const SizedBox(width: 16),

            Text("No reviews yet", style: TextStyle(fontSize: 16, color: Colors.grey[600])),

          ],

        ),

      );

    }

    return Column(

      children: _reviews.take(5).map((r) {

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

      }).toList(),

    );

  }



  Widget _buildSwipeToBookBar() {

    return Positioned(

      bottom: 30,

      left: 20,

      right: 20,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6CBF).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6CBF).withOpacity(0.95),
                    const Color(0xFFFF8E9E).withOpacity(0.95),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: _SwipeToBookButton(
                onCompleted: () {
                  HapticFeedback.heavyImpact();
                  final serviceToPass = Map<String, dynamic>.from(widget.service);
                  final offer = _selectedOffer ?? widget.activeOffer;
                  final offerId = offer?['id']?.toString();
                  final discountedPrice = _getEffectivePrice();
                  final basePrice = (widget.service['_base_price'] != null)
                      ? (double.tryParse(widget.service['_base_price'].toString()) ?? 0)
                      : (double.tryParse(widget.service['price']?.toString() ?? '0') ?? 0);
                  if (offerId != null && offer != null) {
                    serviceToPass['_offer_id'] = offerId;
                    serviceToPass['_offer_title'] = offer['title']?.toString();
                    serviceToPass['_base_price'] = basePrice; // For Standard Rate display
                    serviceToPass['price'] = discountedPrice.toStringAsFixed(0);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentBookingScreen(
                        service: serviceToPass,
                        offerId: offerId,
                        offerDiscountedPrice: offerId != null ? discountedPrice : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

  }



  Widget _buildRelatedCarousel() {

    if (_loadingRelated) return const Center(child: CupertinoActivityIndicator());

    return SizedBox(

      height: 200,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 300,
        itemCount: _relatedServices.length,

        itemBuilder: (context, index) {

          final item = _relatedServices[index];

          return GestureDetector(

            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ServiceDetailedScreen(service: item))),

            child: Container(

              width: 150,

              margin: const EdgeInsets.only(right: 16),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  ClipRRect(

                    borderRadius: BorderRadius.circular(20),

                    child: _buildServiceImage(item, height: 130, width: 150),

                  ),

                  const SizedBox(height: 8),

                  Text(item['name'], maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

                  Text("${item['price']} PKR", style: const TextStyle(color: Color(0xFFFF6CBF), fontSize: 13, fontWeight: FontWeight.w700)),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Future<void> _loadRelatedServices() async {

    try {

      final categoryId = widget.service['category_id']?.toString();

      if (categoryId != null) {

        final services = await _catalog.getServices(categoryId: categoryId, limit: 10);

        if (mounted) {

          setState(() {

            _relatedServices = services.map((s) => s as Map<String, dynamic>).toList();

            _loadingRelated = false;

          });

        }

      }

    } catch (_) {

      if (mounted) setState(() => _loadingRelated = false);

    }

  }

}



// --- Custom Swipe Widget ---

class _SwipeToBookButton extends StatefulWidget {

  final VoidCallback onCompleted;

  const _SwipeToBookButton({required this.onCompleted});



  @override

  State<_SwipeToBookButton> createState() => _SwipeToBookButtonState();

}



class _SwipeToBookButtonState extends State<_SwipeToBookButton> {

  double _dragValue = 0.0;
  static const double _thumbSize = 52.0;
  static const double _trackHeight = 56.0;



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final slideRange = maxWidth - _thumbSize - 16;

      return SizedBox(
        height: _trackHeight,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: double.infinity,
              height: _trackHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(_trackHeight / 2),
              ),
            ),
            Center(
              child: Text(
                "Slide to Book",
                style: TextStyle(
                  color: Colors.white.withOpacity(_dragValue > 0.5 ? 0.0 : 1.0),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 8 + _dragValue * slideRange,
              child: GestureDetector(

                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragValue = (_dragValue + details.delta.dx / slideRange).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (_dragValue > 0.8) {

                    setState(() => _dragValue = 1.0);

                    widget.onCompleted();
                    Future.delayed(const Duration(milliseconds: 400), () {
                      if (mounted) setState(() => _dragValue = 0.0);

                    });

                  } else {

                    setState(() => _dragValue = 0.0);

                  }

                },

                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF6CBF),
                    size: 20,
                  ),
                ),

              ),

            ),

          ],

        ),

      );

    });

  }

}



class _StatItem extends StatelessWidget {

  final String label, value;

  const _StatItem({required this.label, required this.value});



  @override

  Widget build(BuildContext context) {

    return Column(

      children: [

        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),

        const SizedBox(height: 4),

        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

      ],

    );

  }

}