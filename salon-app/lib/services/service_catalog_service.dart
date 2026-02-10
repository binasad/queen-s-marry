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
    // Clear cache if force refresh is requested
    if (forceRefresh) {
      await CacheService.clearServices();
      print('🗑️ Services cache cleared for force refresh');
    }

    // Only use cache if no filters are applied (cache stores all services)
    final hasFilters =
        categoryId != null ||
        minPrice != null ||
        maxPrice != null ||
        (search != null && search.isNotEmpty);

    if (!forceRefresh && !hasFilters && page == 1) {
      final cachedServices = CacheService.getServices();
      if (cachedServices != null && cachedServices.isNotEmpty) {
        print('📦 Loading services from cache');
        // Still fetch in background to update cache
        _fetchAndCacheServices();
        return cachedServices;
      }
    }

    // Fetch from API
    print('🌐 Loading services from API (forceRefresh: $forceRefresh)');
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

    // Save to cache only if no filters (first page, all services)
    if (services.isNotEmpty && !hasFilters && page == 1) {
      await CacheService.saveServices(services);
    }

    return services;
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

  Future<List<dynamic>> getExperts({String? serviceId}) async {
    var endpoint = '/experts';
    if (serviceId != null) endpoint += '?serviceId=$serviceId';

    final response = await _api.get(endpoint, requiresAuth: false);
    final data = response['data'];
    if (data is List) return List<dynamic>.from(data);
    if (data is Map && data['experts'] is List) {
      return List<dynamic>.from(data['experts'] as List);
    }
    return const [];
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
