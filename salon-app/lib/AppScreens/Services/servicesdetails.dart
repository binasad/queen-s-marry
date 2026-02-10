import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../UserScreens/AppointmentBooking.dart';
import '../../services/service_catalog_service.dart';

class ServiceDetailedScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final List<Map<String, dynamic>>? allServices;

  const ServiceDetailedScreen({Key? key, required this.service, this.allServices})
      : super(key: key);

  @override
  State<ServiceDetailedScreen> createState() => _ServiceDetailedScreenState();
}

class _ServiceDetailedScreenState extends State<ServiceDetailedScreen> {
  final ServiceCatalogService _catalog = ServiceCatalogService();
  List<Map<String, dynamic>> _relatedServices = [];
  bool _loadingRelated = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedServices();
  }

  ImageProvider _getImage(Map<String, dynamic> s) {
    final url = s['image_url']?.toString() ?? s['image']?.toString() ?? '';
    if (url.isEmpty) return const AssetImage('assets/FeatherCutting.png');
    return url.startsWith('http') ? NetworkImage(url) : AssetImage(url) as ImageProvider;
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
                      const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(
                        widget.service['description']?.toString() ?? "A premium wellness experience.",
                        style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6), height: 1.6),
                      ),
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
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: _getImage(widget.service), fit: BoxFit.cover),
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

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(label: "Rating", value: "4.9 ★"),
          _StatItem(label: "Reviews", value: "80+"),
          _StatItem(label: "Price", value: "Premium"),
        ],
      ),
    );
  }

  Widget _buildSwipeToBookBar() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Price", style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text("${widget.service['price']} PKR", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _SwipeToBookButton(
                    onCompleted: () {
                      HapticFeedback.heavyImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentBookingScreen(service: widget.service)));
                    },
                  ),
                ),
              ],
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
        physics: const BouncingScrollPhysics(),
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
                    child: Image(image: _getImage(item), height: 130, width: 150, fit: BoxFit.cover),
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
  final double _buttonSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double maxWidth = constraints.maxWidth;
      double slideRange = maxWidth - _buttonSize - 10;

      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            const Center(
              child: Text(
                "Slide to Book",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Positioned(
              left: _dragValue * slideRange + 5,
              top: 5,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragValue = (_dragValue + details.delta.dx / slideRange).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_dragValue > 0.8) {
                    setState(() => _dragValue = 1.0);
                    widget.onCompleted();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _dragValue = 0.0);
                    });
                  } else {
                    setState(() => _dragValue = 0.0);
                  }
                },
                child: Container(
                  width: _buttonSize,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6CBF),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
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