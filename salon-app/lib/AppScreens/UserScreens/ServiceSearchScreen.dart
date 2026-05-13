import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/service_catalog_service.dart';
import '../../utils/debouncer.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/cart_icon_button.dart';
import '../Services/servicesdetails.dart';

const _kPrimary = Color(0xFFFF0068);
const _kAccent = Color(0xFFFF6CBF);
const _kBg = Color(0xFFFBFBFD);

/// Full-screen service search. Live-queries the backend's `?search=...`
/// endpoint on `services` with debouncing, shows results, taps a card to push
/// the standard `ServiceDetailedScreen`.
class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ServiceCatalogService _catalog = ServiceCatalogService();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 350));

  /// Monotonically increasing token so a slow earlier response can't overwrite
  /// the results of a faster, more recent query.
  int _queryToken = 0;

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _lastQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    // Open keyboard immediately so users can type without an extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.isEmpty) {
      // Clearing the field → drop results, no need to hit the backend.
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debouncer.call(_runSearch);
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    final token = ++_queryToken;
    try {
      final raw = await _catalog.getServices(search: q, limit: 50);
      if (!mounted || token != _queryToken) return;
      final list = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _results = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _queryToken) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchField(),
        titleSpacing: 0,
        actions: const [CartIconButton(iconColor: Colors.black87)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _runSearch(),
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search services…',
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: InputBorder.none,
        isCollapsed: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                onPressed: () {
                  _controller.clear();
                  _onChanged();
                  _focusNode.requestFocus();
                },
              ),
      ),
    );
  }

  Widget _buildBody() {
    final q = _controller.text.trim();
    if (q.isEmpty) return _buildPrompt();
    if (_loading && _results.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null && _results.isEmpty) {
      return _buildError();
    }
    if (_results.isEmpty) return _buildNoResults(q);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ServiceResultTile(
        service: _results[i],
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailedScreen(service: _results[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 88, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Search services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Type a service name (e.g. "facial", "haircut", "bridal makeup").',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(String q) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No services found for "$q"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a shorter or different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Could not search right now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _runSearch,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceResultTile extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  const _ServiceResultTile({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = service['price']?.toString();
    final duration = service['duration']?.toString();
    final categoryName = service['category_name']?.toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service['name']?.toString() ?? 'Service',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    if (categoryName != null && categoryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        categoryName,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (price != null && price.isNotEmpty)
                          Text(
                            'PKR $price',
                            style: const TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        if (price != null && price.isNotEmpty &&
                            duration != null && duration.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 3, height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (duration != null && duration.isNotEmpty)
                          Text(
                            duration,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = service['image_url']?.toString() ?? service['image']?.toString() ?? '';
    const w = 64.0, h = 64.0;
    if (url.isEmpty) {
      return Image.asset('assets/FeatherCutting.png', width: w, height: h, fit: BoxFit.cover);
    }
    if (url.startsWith('http')) {
      return CachedImageWidget(imageUrl: url, width: w, height: h, fit: BoxFit.cover);
    }
    return Image.asset(url, width: w, height: h, fit: BoxFit.cover);
  }
}
