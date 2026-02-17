import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorites_service.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) => FavoritesService());

/// List of all favorites (services + courses)
final favoritesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  return service.getFavorites();
});

/// Check if a service is favorited
Future<bool> isServiceFavorite(Ref ref, String serviceId) async {
  final service = ref.read(favoritesServiceProvider);
  return service.isServiceFavorite(serviceId);
}

/// Check if a course is favorited
Future<bool> isCourseFavorite(Ref ref, String courseId) async {
  final service = ref.read(favoritesServiceProvider);
  return service.isCourseFavorite(courseId);
}
