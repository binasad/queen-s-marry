import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:salon/AppScreens/UserScreens/userDrawer.dart';
import '../../Manager/ExpertManager.dart';
import '../../Manager/OfferManager.dart';
import '../../services/offer_service.dart';
import '../../services/service_catalog_service.dart';
import '../../services/user_service.dart';
import '../../services/websocket_service.dart';
import '../../providers/services_provider.dart';
import '../../utils/debouncer.dart';
import '../../utils/error_handler.dart';
import '../../utils/haptic_feedback.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/cached_image.dart';
import '../Services/userServices.dart';
import '../Services/ApiCategoryServicesTabbed.dart';
import 'AppointmentBooking.dart';
import 'Course Screens/CourseDetails.dart';
import 'Course Screens/CoursesScreen.dart';
import 'UserNotifications.dart';
import '../PersonalInfo.dart';
import '../../services/course_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart' as app_auth;

class UserHome extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;
  const UserHome({super.key, this.onRefresh});

  /// Custom route with bottom-up slide animation for manual navigation
  static Route<dynamic> route({VoidCallback? onRefresh}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          UserHome(onRefresh: onRefresh),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  ConsumerState<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends ConsumerState<UserHome>
    with SingleTickerProviderStateMixin {
  String location = "I8 Markaz, ISB";
  final TextEditingController _searchController = TextEditingController();
  late Debouncer _searchDebouncer;

  // Animation controller for the internal staggered entrance
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  List<Map<String, dynamic>> filteredOffers = [];
  List<Map<String, dynamic>> filteredExperts = [];
  String name = "Guest", email = "", profile = "";

  // API Services
  final OfferService _offerService = OfferService();
  final ServiceCatalogService _catalogService = ServiceCatalogService();
  final UserService _userService = UserService();

  // Loading states
  bool _offersLoading = true;
  bool _expertsLoading = true;
  bool _userLoading = true;

  // Offer card slider
  late PageController _offerPageController;
  int _currentOfferPage = 0;

  StreamSubscription<Map<String, dynamic>>? _offersUpdatedSubscription;

  @override
  void initState() {
    super.initState();

    // Setup Entrance Animation (Bottom to Up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutBack,
          ),
        );

    _entranceController.forward();

    _offerPageController = PageController(
      viewportFraction: 0.88,
      initialPage: 0,
    );
    _offerPageController.addListener(() {
      final page = _offerPageController.page?.round() ?? 0;
      if (mounted && page != _currentOfferPage) {
        setState(() => _currentOfferPage = page);
      }
    });

    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

    // Load all data from APIs
    _loadAllData();

    _searchController.addListener(() {
      _searchDebouncer.call(_onSearchChanged);
    });

    // Refresh offers when admin updates (WebSocket)
    _offersUpdatedSubscription = WebSocketService().offersUpdatedStream.listen((_) {
      if (mounted) {
        debugPrint('📦 Offers updated via WebSocket - refreshing...');
        loadOffers(forceRefresh: true);
      }
    });
  }

  /// Load all data from APIs concurrently
  Future<void> _loadAllData() async {
    await Future.wait([loadUserData(), loadOffers(), loadExperts()]);
    // Guard: widget may have been disposed (e.g. user navigated away quickly)
    if (!mounted) return;
    ref.read(servicesProvider.notifier).loadCategories();
  }

  /// Refresh all data (can be called on pull-to-refresh)
  Future<void> refreshData() async {
    await Future.wait([
      loadOffers(forceRefresh: true),
      loadExperts(forceRefresh: true),
    ]);
    if (!mounted) return;
    ref.read(servicesProvider.notifier).loadCategories(forceRefresh: true);
  }

  @override
  void dispose() {
    _offersUpdatedSubscription?.cancel();
    _entranceController.dispose();
    _searchController.dispose();
    _offerPageController.dispose();
    super.dispose();
  }

  // API loading logic
  Future<void> loadOffers({bool forceRefresh = false}) async {
    if (mounted) setState(() => _offersLoading = true);
    try {
      debugPrint('📦 Loading offers${forceRefresh ? ' (refresh)' : ''}...');
      final offers = await _offerService.getOffers(isActive: true, forceRefresh: forceRefresh);
      debugPrint('📦 Loaded ${offers.length} offers from API');
      if (mounted) {
        final formattedOffers = offers.map((offer) {
          final discount = offer['discount_percentage'] != null
              ? '${offer['discount_percentage']}%'
              : offer['discount_amount'] != null
              ? 'Rs.${offer['discount_amount']}'
              : 'Special';
          return {
            'id': offer['id']?.toString() ?? '',
            'title': offer['title']?.toString() ?? '',
            'discount': discount,
            'image': offer['image_url']?.toString() ?? 'assets/bgbg.png',
            'duration': _getDurationText(
              offer['start_date'],
              offer['end_date'],
            ),
            'apply_to': offer['apply_to']?.toString() ?? offer['applyTo']?.toString(),
            'service_id': offer['service_id']?.toString(),
            'course_id': offer['course_id']?.toString(),
            'discount_percentage': offer['discount_percentage'],
            'discount_amount': offer['discount_amount'],
          };
        }).toList();
        setState(() {
          filteredOffers = formattedOffers;
          _offersLoading = false;
          _currentOfferPage = 0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load offers: $e');
      if (mounted) {
        setState(() {
          filteredOffers = OfferManager.offers
              .map((o) => Map<String, dynamic>.from(o))
              .toList();
          _offersLoading = false;
        });
      }
    }
  }

  String _getDurationText(dynamic startDate, dynamic endDate) {
    if (startDate == null || endDate == null) return 'Limited';
    try {
      final end = DateTime.parse(endDate.toString());
      final now = DateTime.now();
      final daysLeft = end.difference(now).inDays;
      if (daysLeft < 0) return 'Expired';
      if (daysLeft == 0) return 'Ends today';
      return '$daysLeft days left';
    } catch (e) {
      return 'Limited';
    }
  }

  /// Load experts from API
  Future<void> loadExperts({bool forceRefresh = false}) async {
    if (mounted) setState(() => _expertsLoading = true);
    try {
      debugPrint('👨‍💼 Loading experts${forceRefresh ? ' (refresh)' : ''}...');
      final experts = await _catalogService.getExperts(forceRefresh: forceRefresh);
      debugPrint('👨‍💼 Loaded ${experts.length} experts from API');
      if (mounted) {
        final formattedExperts = experts.map((expert) {
          return {
            'id': expert['id']?.toString() ?? '',
            'name': expert['name']?.toString() ?? 'Expert',
            'specialty':
                expert['specialty']?.toString() ??
                expert['role']?.toString() ??
                'Specialist',
            'image':
                expert['profile_image_url']?.toString() ??
                expert['image']?.toString() ??
                'assets/profile.jpg',
            'rating': expert['rating']?.toString() ?? '4.9',
          };
        }).toList();
        setState(() {
          filteredExperts = formattedExperts;
          _expertsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load experts: $e');
      if (mounted) {
        setState(() {
          filteredExperts = ExpertManager.experts
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _expertsLoading = false;
        });
      }
    }
  }

  Future<void> loadUserData() async {
    if (mounted) setState(() => _userLoading = true);

    // First try AuthProvider (cached data - fast)
    final authProvider = provider_package.Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );
    if (authProvider.user != null) {
      final userData = authProvider.user!;
      setState(() {
        name = userData['name']?.toString() ?? "Guest";
        email = userData['email']?.toString() ?? "";
        profile =
            userData['profile_image_url']?.toString() ??
            userData['profileImage']?.toString() ??
            "";
        _userLoading = false;
      });

      // Return early if we have valid name
      if (name.isNotEmpty && name != "Guest") return;
    }

    // Try to fetch fresh data from API
    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      if (token != null && token.isNotEmpty) {
        final profileData = await _userService.getProfile();
        final user = profileData['user'] as Map<String, dynamic>?;

        if (user != null && mounted) {
          setState(() {
            name = user['name']?.toString() ?? name;
            email = user['email']?.toString() ?? email;
            profile = user['profile_image_url']?.toString() ?? profile;
            _userLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }

    if (mounted) setState(() => _userLoading = false);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      // Reset to full lists
      loadOffers();
      loadExperts();
      return;
    }

    setState(() {
      // Filter offers
      filteredOffers = filteredOffers.where((offer) {
        final title = (offer['title'] ?? '').toString().toLowerCase();
        final discount = (offer['discount'] ?? '').toString().toLowerCase();
        return title.contains(query) || discount.contains(query);
      }).toList();

      // Filter experts
      filteredExperts = filteredExperts.where((expert) {
        final name = (expert['name'] ?? '').toString().toLowerCase();
        final specialty = (expert['specialty'] ?? '').toString().toLowerCase();
        return name.contains(query) || specialty.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final categoriesLoading = ref.watch(categoriesLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FB),
      drawer: UserDrawer(userName: name, userEmail: email, profileImageUrl: profile),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Stack(
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF5F8),
                      Color(0xFFFAF9FB),
                      Colors.white,
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildTopBar(),
                    _buildLocationCard(),
                    _buildSearchBar(),
                    _buildSectionHeader("Special Offers"),
                    _buildOffersList(),
                    _buildSectionHeader(
                      "Our Services",
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ServicesScreen()),
                        );
                      },
                    ),
                    _buildServicesList(categories),
                    _buildSectionHeader("Our Experts"),
                    _buildExpertsList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Methods (Cleaned of Icons as requested) ---

  Widget _buildTopBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserPersonalInfo(),
                  ),
                );
              },
              child: profile.isNotEmpty
                  ? CachedCircleImage(imageUrl: profile, radius: 24)
                  : CircleAvatar(
                      radius: 24,
                      backgroundImage: const AssetImage('assets/profile.jpg'),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3A),
                      ),
                    ),
                    const Text(
                      "Welcome to Queens Saloon",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF2D2D3A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D3A),
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE91E63), size: 20),
              const SizedBox(width: 12),
              Text(
                location,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search services...',
            prefixIcon: const Icon(
              CupertinoIcons.search,
              color: Color(0xFFE91E63),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersList() {
    if (_offersLoading) {
      return SliverToBoxAdapter(
        child: HorizontalListSkeletonLoader(
          itemCount: 4,
          itemHeight: 200,
          itemWidth: 280,
        ),
      );
    }

    if (filteredOffers.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 40,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  'No offers available',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _offerPageController,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: filteredOffers.length,
              itemBuilder: (context, index) {
                final offer = filteredOffers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) => _buildOfferCard(
                      offer['title'] ?? '',
                      offer['discount'] ?? '',
                      offer['image'] ?? 'assets/bgbg.png',
                      duration: offer['duration'] ?? 'Limited',
                      serviceId: offer['service_id']?.toString(),
                      courseId: offer['course_id']?.toString(),
                      onTap: () => _onOfferTap(offer),
                      cardWidth: constraints.maxWidth,
                    ),
                  ),
                );
              },
            ),
          ),
          if (filteredOffers.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                filteredOffers.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentOfferPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentOfferPage == index
                        ? const Color(0xFFE91E63)
                        : const Color(0xFFE91E63).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _applyOfferDiscount(double price, Map<String, dynamic> offer) {
    final pct = offer['discount_percentage'];
    final amt = offer['discount_amount'];
    if (pct != null) {
      final val = double.tryParse(pct.toString()) ?? 0;
      return (price * (1 - val / 100)).roundToDouble();
    }
    if (amt != null) {
      final val = double.tryParse(amt.toString()) ?? 0;
      return (price - val).clamp(0.0, double.infinity);
    }
    return price;
  }

  Future<void> _onOfferTap(Map<String, dynamic> offer) async {
    final serviceId = offer['service_id']?.toString();
    final courseId = offer['course_id']?.toString();
    final applyTo = offer['apply_to']?.toString() ?? offer['applyTo']?.toString() ??
        (serviceId != null && serviceId.isNotEmpty
            ? 'service'
            : courseId != null && courseId.isNotEmpty
                ? 'course'
                : 'all');

    // all_services, all_courses, or all -> show bottom sheet with appropriate options
    if (applyTo == 'all_services' || applyTo == 'all_courses' || applyTo == 'all') {
      HapticHelper.mediumImpact();
      if (!mounted) return;
      final showServices = applyTo == 'all_services' || applyTo == 'all';
      final showCourses = applyTo == 'all_courses' || applyTo == 'all';
      final message = applyTo == 'all_services'
          ? 'This offer applies to all services'
          : applyTo == 'all_courses'
              ? 'This offer applies to all courses'
              : 'This offer applies to all services and courses';

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offer['title'] ?? 'Special Offer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (showServices)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServicesScreen(activeOffer: offer),
                            ),
                          );
                        },
                        icon: const Icon(Icons.spa_outlined),
                        label: const Text('Browse Services'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  if (showServices && showCourses) const SizedBox(height: 12),
                  if (showCourses)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoursesScreen(activeOffer: offer),
                            ),
                          );
                        },
                        icon: const Icon(Icons.school_outlined),
                        label: const Text('Browse Courses'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE91E63),
                          side: const BorderSide(color: Color(0xFFE91E63)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (applyTo == 'service' && serviceId != null && serviceId.isNotEmpty) {
      HapticHelper.mediumImpact();
      try {
        final service = await ServiceCatalogService().getServiceById(serviceId);
        if (mounted && service.isNotEmpty) {
          final basePrice =
              (double.tryParse(service['price']?.toString() ?? '0') ?? 0);
          final discountedPrice = _applyOfferDiscount(basePrice, offer);
          final serviceWithOffer = Map<String, dynamic>.from(service);
          serviceWithOffer['_base_price'] = basePrice;
          serviceWithOffer['price'] = discountedPrice;
          serviceWithOffer['_offer_id'] = offer['id']?.toString();
          serviceWithOffer['_offer_title'] = offer['title']?.toString();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentBookingScreen(
                service: serviceWithOffer,
                offerId: offer['id']?.toString(),
                offerDiscountedPrice: discountedPrice,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to load service: $e');
        if (mounted) ErrorHandler.show(context, e);
      }
    } else if (applyTo == 'course' && courseId != null && courseId.isNotEmpty) {
      HapticHelper.mediumImpact();
      try {
        final raw = await CourseService().getCourseById(courseId);
        if (mounted && raw.isNotEmpty) {
          final basePrice =
              (double.tryParse(raw['price']?.toString() ?? '0') ?? 0);
          final discountedPrice = _applyOfferDiscount(basePrice, offer);
          final course = {
            'id': raw['id']?.toString() ?? '',
            'title': raw['title']?.toString() ?? 'Course',
            'duration': raw['duration']?.toString() ?? 'Flexible',
            'price': discountedPrice.toStringAsFixed(0),
            'image': raw['image_url']?.toString() ?? raw['image'] ?? '',
            'description': raw['description']?.toString() ?? '',
            'subjects':
                (raw['description']?.toString().contains(
                      'Subjects Included:',
                    ) ??
                    false)
                ? raw['description']
                      .toString()
                      .split('Subjects Included:')[1]
                      .split(',')
                      .map((e) => e.trim())
                      .toList()
                : ['Professional Training'],
            '_offer_id': offer['id']?.toString(),
            '_offer_title': offer['title']?.toString(),
          };
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to load course: $e');
        if (mounted) ErrorHandler.show(context, e);
      }
    }
  }

  Widget _buildOfferCard(
    String title,
    String discount,
    String imagePath, {
    String duration = 'Limited',
    String? serviceId,
    String? courseId,
    VoidCallback? onTap,
    double? cardWidth,
  }) {
    final hasLink =
        (serviceId != null && serviceId.isNotEmpty) ||
        (courseId != null && courseId.isNotEmpty) ||
        ((serviceId == null || serviceId.isEmpty) && (courseId == null || courseId.isEmpty));
    return GestureDetector(
      onTap: hasLink ? onTap : null,
      child: Container(
        width: cardWidth ?? 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: imagePath.startsWith('http')
                    ? CachedImageWidget(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        memCacheWidth: 560,
                        memCacheHeight: 360,
                        placeholderAsset: null,
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE91E63).withOpacity(0.1),
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        'Claim Now',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(List categories) {
    final categoriesLoading = ref.watch(categoriesLoadingProvider);

    if (categoriesLoading && categories.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'No services available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index] as Map<String, dynamic>;
            final categoryName = (cat['name'] ?? '').toString();
            final id = (cat['id'] ?? '').toString();
            final imageUrl = (cat['image_url'] ?? '').toString();
            final displayName = categoryName
                .replaceAll(' Services', '')
                .replaceAll('Service', '')
                .trim();

            return Padding(
              padding: EdgeInsets.only(
                right: index < categories.length - 1 ? 16 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticHelper.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApiCategoryServicesTabbedScreen(
                        categoryId: id,
                        title: categoryName,
                      ),
                    ),
                  );
                },
                child: _buildServiceIcon(imageUrl, displayName),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceIcon(String imageUrl, String label) {
    return SizedBox(
      width: 85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholderAsset: 'assets/FeatherCutting.png',
                    )
                  : Image.asset(
                      'assets/FeatherCutting.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D3A),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpertsList() {
    if (_expertsLoading) {
      return SliverToBoxAdapter(
        child: HorizontalListSkeletonLoader(
          itemCount: 5,
          itemHeight: 200,
          itemWidth: 160,
        ),
      );
    }

    if (filteredExperts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'No experts available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredExperts.length,
          itemBuilder: (context, index) {
            final expert = filteredExperts[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index < filteredExperts.length - 1 ? 16 : 0,
              ),
              child: _buildExpertCard(
                expert['name'] ?? 'Expert',
                expert['specialty'] ?? 'Specialist',
                expert['image'] ?? 'assets/profile.jpg',
                rating: expert['rating'] ?? '4.9',
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpertCard(
    String name,
    String specialty,
    String imagePath, {
    String rating = '4.9',
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: imagePath.startsWith('http')
                  ? CachedImageWidget(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      width: 160,
                      height: 200,
                      memCacheWidth: 320,
                      memCacheHeight: 400,
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB800),
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        specialty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
