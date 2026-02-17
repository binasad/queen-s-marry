import 'api_service.dart';
import 'cache_service.dart';

class ServiceCatalogService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async {
    // Try to get from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedCategories = CacheService.getCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        print('📦 Loading categories from cache');
        // Still fetch in background to update cache
        _fetchAndCacheCategories();
        return cachedCategories;
      }
    }

    // Fetch from API
    print('🌐 Loading categories from API');
    final response = await _api.get('/categories', requiresAuth: false);
    // Backend format: { success: true, data: { categories: [...] } }
    // Some older code expected: { data: [...] }
    final data = response['data'];
    List<dynamic> categories = const [];

    if (data is List) {
      categories = List<dynamic>.from(data);
    } else if (data is Map && data['categories'] is List) {
      categories = List<dynamic>.from(data['categories'] as List);
    }

    // Save to cache
    if (categories.isNotEmpty) {
      await CacheService.saveCategories(categories);
    }

    return categories;
  }

  /// Fetch categories in background and update cache
  Future<void> _fetchAndCacheCategories() async {
    try {
      final response = await _api.get('/categories', requiresAuth: false);
      final data = response['data'];
      List<dynamic> categories = const [];

      if (data is List) {
        categories = List<dynamic>.from(data);
      } else if (data is Map && data['categories'] is List) {
        categories = List<dynamic>.from(data['categories'] as List);
      }

      if (categories.isNotEmpty) {
        await CacheService.saveCategories(categories);
        print('✅ Categories cache updated in background');
      }
    } catch (e) {
      print('⚠️ Failed to update categories cache: $e');
    }
  }

  Future<List<dynamic>> getServices({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 200,
    bool forceRefresh = false,
  }) async {
    final hasFilters =
        minPrice != null ||
        maxPrice != null ||
        (search != null && search.isNotEmpty);

    // Category-only filter: use per-category cache
    if (categoryId != null && !hasFilters && page == 1) {
      if (forceRefresh) {
        await CacheService.clearServicesByCategory(categoryId);
      } else {
        final cached = CacheService.getServicesByCategory(categoryId);
        if (cached != null && cached.isNotEmpty) {
          _fetchAndCacheServicesByCategory(categoryId, limit);
          return cached;
        }
      }
    }

    // No filters: use global services cache
    if (forceRefresh) {
      await CacheService.clearServices();
    }
    if (!forceRefresh && !hasFilters && page == 1) {
      final cachedServices = CacheService.getServices();
      if (cachedServices != null && cachedServices.isNotEmpty) {
        _fetchAndCacheServices();
        return cachedServices;
      }
    }

    // Fetch from API
    var endpoint = '/services?page=$page&limit=$limit&isActive=true';
    if (categoryId != null) endpoint += '&categoryId=$categoryId';
    if (minPrice != null) endpoint += '&minPrice=$minPrice';
    if (maxPrice != null) endpoint += '&maxPrice=$maxPrice';
    if (search != null) endpoint += '&search=$search';

    final response = await _api.get(endpoint, requiresAuth: false);
    // Backend format: { success: true, data: { services: [...] } }
    final data = response['data'];
    List<dynamic> services = const [];

    if (data is Map && data['services'] is List) {
      services = List<dynamic>.from(data['services'] as List);
    } else if (data is List) {
      services = List<dynamic>.from(data);
    }

    // Save to cache
    if (services.isNotEmpty && page == 1) {
      if (categoryId != null && !hasFilters) {
        await CacheService.saveServicesByCategory(categoryId, services);
      } else if (!hasFilters) {
        await CacheService.saveServices(services);
      }
    }

    return services;
  }

  Future<void> _fetchAndCacheServicesByCategory(String categoryId, int limit) async {
    try {
      final response = await _api.get(
        '/services?page=1&limit=$limit&isActive=true&categoryId=$categoryId',
        requiresAuth: false,
      );
      final data = response['data'];
      List<dynamic> services = const [];
      if (data is Map && data['services'] is List) {
        services = List<dynamic>.from(data['services'] as List);
      } else if (data is List) {
        services = List<dynamic>.from(data);
      }
      if (services.isNotEmpty) {
        await CacheService.saveServicesByCategory(categoryId, services);
      }
    } catch (_) {}
  }

  /// Fetch services in background and update cache
  Future<void> _fetchAndCacheServices() async {
    try {
      final response = await _api.get(
        '/services?page=1&limit=200&isActive=true',
        requiresAuth: false,
      );
      final data = response['data'];
      List<dynamic> services = const [];

      if (data is Map && data['services'] is List) {
        services = List<dynamic>.from(data['services'] as List);
      } else if (data is List) {
        services = List<dynamic>.from(data);
      }

      if (services.isNotEmpty) {
        await CacheService.saveServices(services);
        print('✅ Services cache updated in background');
      }
    } catch (e) {
      print('⚠️ Failed to update services cache: $e');
    }
  }

  Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    final response = await _api.get(
      '/services/$serviceId',
      requiresAuth: false,
    );
    // Backend format: { success: true, data: { service: {...} } }
    final data = response['data'];
    if (data is Map && data['service'] is Map) {
      return Map<String, dynamic>.from(data['service'] as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  /// Get experts - cache-first when no serviceId filter
  Future<List<dynamic>> getExperts({String? serviceId, bool forceRefresh = false}) async {
    if (serviceId == null && !forceRefresh) {
      final cached = CacheService.getExperts();
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheExperts();
        return cached;
      }
    } else if (forceRefresh) {
      await CacheService.clearExperts();
    }

    var endpoint = '/experts';
    if (serviceId != null) endpoint += '?serviceId=$serviceId';

    final response = await _api.get(endpoint, requiresAuth: false);
    final data = response['data'];
    List<dynamic> experts = const [];
    if (data is List) {
      experts = List<dynamic>.from(data);
    } else if (data is Map && data['experts'] is List) {
      experts = List<dynamic>.from(data['experts'] as List);
    }

    if (experts.isNotEmpty && serviceId == null) {
      await CacheService.saveExperts(experts);
    }
    return experts;
  }

  Future<void> _fetchAndCacheExperts() async {
    try {
      final response = await _api.get('/experts', requiresAuth: false);
      final data = response['data'];
      List<dynamic> experts = const [];
      if (data is List) {
        experts = List<dynamic>.from(data);
      } else if (data is Map && data['experts'] is List) {
        experts = List<dynamic>.from(data['experts'] as List);
      }
      if (experts.isNotEmpty) await CacheService.saveExperts(experts);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> createService({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required int duration,
    String? imageUrl,
    List<String>? tags,
  }) async {
    final response = await _api.post('/services', {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (tags != null) 'tags': tags,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _api.put('/services/$serviceId', updates);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteService(String serviceId) async {
    await _api.delete('/services/$serviceId');
  }
}
