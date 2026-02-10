import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/service_catalog_service.dart';
import '../../services/websocket_service.dart';
import 'ApiCategoryServicesTabbed.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _servicesSubscription;

  bool _loading = true;
  String? _error;
  List<dynamic> _categories = [];

  // Refined Color Palette
  static const Color _brandColor = Color(0xFFE91E63);
  static const Color _bgColor = Color(0xFFFBFBFD); // Off-white/Apple style background

  static const Map<String, String> _images = {
    'hair services': 'assets/FeatherCutting.png',
    'makeup services': 'assets/MakeUp.jpg',
    'mehndi services': 'assets/Mehndi.jpg',
    'photoshoot services': 'assets/PhotoShoot.jpg',
    'shoot services': 'assets/PhotoShoot.jpg',
    'waxing services': 'assets/Waxing.jpg',
    'facial services': 'assets/FruitFacial.jpg',
    'massage services': 'assets/DeepTissueMassage.jpg',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    _servicesSubscription = _wsService.servicesUpdatedStream.listen((data) {
      if (mounted) _load(silent: true);
    });
    _wsService.connect();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final cats = await _catalog.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _bgColor,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Catalog",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandColor, strokeWidth: 2))
          : _error != null
              ? _buildErrorState()
              : _buildCategoryGrid(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade200),
          const SizedBox(height: 16),
          const Text("Something went wrong", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          TextButton(onPressed: _load, child: const Text("Try Again", style: TextStyle(color: _brandColor))),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return RefreshIndicator(
      color: _brandColor,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85, // More vertical for a modern look
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index] as Map<String, dynamic>;
          final name = (cat['name'] ?? '').toString();
          final id = (cat['id'] ?? '').toString();
          final apiImg = (cat['image_url'] ?? '').toString();
          final fallbackAsset = _images[name.toLowerCase()] ?? 'assets/FruitFacial.jpg';

          return _CategoryCard(
            name: name,
            imageUrl: apiImg,
            fallbackAsset: fallbackAsset,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApiCategoryServicesTabbedScreen(
                    categoryId: id,
                    title: name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String fallbackAsset;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Image Background
                Positioned.fill(
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(widget.imageUrl, fit: BoxFit.cover)
                      : Image.asset(widget.fallbackAsset, fit: BoxFit.cover),
                ),
                // Premium Soft Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}