import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_catalog_service.dart';
import '../services/cache_service.dart';

/// Services Provider - Manages services and categories state
class ServicesNotifier extends StateNotifier<ServicesState> {
  final ServiceCatalogService _catalog = ServiceCatalogService();

  ServicesNotifier() : super(ServicesState.initial()) {
    // Load from cache first for instant UI
    _loadCategoriesFromCache();
    // Then load from API
    loadCategories();
  }

  /// Load categories from cache instantly (for better UX)
  void _loadCategoriesFromCache() {
    final cachedCategories = CacheService.getCategories();
    if (cachedCategories != null && cachedCategories.isNotEmpty) {
      state = state.copyWith(categories: cachedCategories);
    }
  }

  /// Load categories with caching
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (state.categoriesLoading) return; // Prevent duplicate calls

    state = state.copyWith(categoriesLoading: true);

    try {
      print('🏷️ Loading categories from API...');
      final categories = await _catalog.getCategories(
        forceRefresh: forceRefresh,
      );
      print('🏷️ Loaded ${categories.length} categories from API');
      state = state.copyWith(
        categories: categories,
        categoriesLoading: false,
        categoriesError: null,
      );
    } catch (e) {
      print('❌ Failed to load categories: $e');
      state = state.copyWith(
        categoriesLoading: false,
        categoriesError: e.toString(),
      );
    }
  }

  /// Load services with caching
  Future<void> loadServices({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? search,
    bool forceRefresh = false,
  }) async {
    if (state.servicesLoading) return; // Prevent duplicate calls

    state = state.copyWith(servicesLoading: true);

    try {
      final services = await _catalog.getServices(
        categoryId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        search: search,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        services: services,
        servicesLoading: false,
        servicesError: null,
      );
    } catch (e) {
      state = state.copyWith(
        servicesLoading: false,
        servicesError: e.toString(),
      );
    }
  }

  /// Get service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      return await _catalog.getServiceById(serviceId);
    } catch (e) {
      state = state.copyWith(servicesError: e.toString());
      return null;
    }
  }

  /// Refresh services and categories (invalidate cache)
  Future<void> refresh() async {
    CacheService.clearServices();
    CacheService.clearCategories();
    await loadCategories(forceRefresh: true);
    await loadServices(forceRefresh: true);
  }
}

/// Services State
class ServicesState {
  final List<dynamic> categories;
  final List<dynamic> services;
  final bool categoriesLoading;
  final bool servicesLoading;
  final String? categoriesError;
  final String? servicesError;

  ServicesState({
    required this.categories,
    required this.services,
    required this.categoriesLoading,
    required this.servicesLoading,
    this.categoriesError,
    this.servicesError,
  });

  factory ServicesState.initial() {
    return ServicesState(
      categories: [],
      services: [],
      categoriesLoading: false,
      servicesLoading: false,
    );
  }

  ServicesState copyWith({
    List<dynamic>? categories,
    List<dynamic>? services,
    bool? categoriesLoading,
    bool? servicesLoading,
    String? categoriesError,
    String? servicesError,
  }) {
    return ServicesState(
      categories: categories ?? this.categories,
      services: services ?? this.services,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      servicesLoading: servicesLoading ?? this.servicesLoading,
      categoriesError: categoriesError ?? this.categoriesError,
      servicesError: servicesError ?? this.servicesError,
    );
  }
}

/// Riverpod Provider for Services
final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>(
  (ref) {
    return ServicesNotifier();
  },
);

/// Convenience providers
final categoriesProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(servicesProvider).categories;
});

final servicesListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(servicesProvider).services;
});

final categoriesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(servicesProvider).categoriesLoading;
});

final servicesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(servicesProvider).servicesLoading;
});
