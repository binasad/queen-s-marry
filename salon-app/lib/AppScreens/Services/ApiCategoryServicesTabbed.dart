import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../../services/service_catalog_service.dart';
import '../../widgets/cached_image.dart';
import '../../services/websocket_service.dart';
import 'servicesdetails.dart';

class ApiCategoryServicesTabbedScreen extends StatefulWidget {
  final String categoryId;
  final String title;

  const ApiCategoryServicesTabbedScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  State<ApiCategoryServicesTabbedScreen> createState() =>
      _ApiCategoryServicesTabbedScreenState();
}

class _ApiCategoryServicesTabbedScreenState
    extends State<ApiCategoryServicesTabbedScreen>
    with TickerProviderStateMixin {
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _servicesSubscription;
  bool _loading = true;
  String? _error;
  List<dynamic> _allServices = [];
  List<String> _tabs = [];
  Map<String, List<dynamic>> _servicesByTag = {};
  TabController? _tabController;

  // Premium Theme Colors
  static const Color _brandColor = Color(0xFFE91E63); // Deep Pink
  static const Color _bgColor = Color(0xFFFBFBFD); // Apple-style off-white
  static const Color _surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _load();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    _tabController?.dispose();
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
      final items = await _catalog.getServices(
        categoryId: widget.categoryId,
        limit: 500,
      );

      Map<String, List<dynamic>> grouped = {};
      Set<String> uniqueTags = {};

      for (var service in items) {
        final tags = service['tags'] as List<dynamic>? ?? [];
        if (tags.isEmpty) {
          uniqueTags.add('All');
          grouped.putIfAbsent('All', () => []).add(service);
        } else {
          for (var tag in tags) {
            final tagStr = tag.toString().trim();
            if (tagStr.isNotEmpty) {
              uniqueTags.add(tagStr);
              grouped.putIfAbsent(tagStr, () => []).add(service);
            }
          }
        }
      }

      final sortedTabs = uniqueTags.toList()
        ..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;
          return a.compareTo(b);
        });

      if (!mounted) return;

      bool tabsChanged = _tabs.length != sortedTabs.length;
      setState(() {
        _allServices = items;
        _tabs = sortedTabs;
        _servicesByTag = grouped;
        _loading = false;
        if (tabsChanged || _tabController == null) {
          _tabController?.dispose();
          _tabController = TabController(length: _tabs.length, vsync: this);
        }
      });
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        bottom: _tabs.isEmpty || _loading
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Center(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: _brandColor,
                    indicatorWeight: 3,
                    labelColor: _brandColor,
                    unselectedLabelColor: Colors.black38,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : _error != null
          ? _buildErrorState()
          : _tabs.isEmpty
          ? _buildServicesList(_allServices)
          : TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((tab) => _buildServicesList(_servicesByTag[tab] ?? []))
                  .toList(),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade200,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Again'),
            style: TextButton.styleFrom(foregroundColor: _brandColor),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<dynamic> services) {
    if (services.isEmpty) {
      return const Center(
        child: Text('No services found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      color: _brandColor,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index] as Map<String, dynamic>;
          final name = s['name']?.toString() ?? '';
          final desc = s['description']?.toString() ?? '';
          final price = s['price']?.toString() ?? '0';
          final duration = s['duration']?.toString() ?? '0';
          final imgUrl = s['image_url']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final serviceMap = {
                  'id': s['id']?.toString() ?? '',
                  'name': name,
                  'description': desc,
                  'price': price,
                  'duration': '$duration min',
                  'image_url': imgUrl,
                  'category_id':
                      s['category_id']?.toString() ?? widget.categoryId,
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailedScreen(
                      service: serviceMap,
                      allServices: [],
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imgUrl.isNotEmpty
                          ? CachedImageWidget(
                              imageUrl: imgUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            )
                          : _buildPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    // Info Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc.isEmpty
                                ? 'Pamper yourself with our $name'
                                : desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _brandColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PKR $price',
                                    style: const TextStyle(
                                      color: _brandColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.black26,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$duration min',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade100,
      child: Icon(Icons.spa_outlined, color: Colors.grey.shade400, size: 30),
    );
  }
}
