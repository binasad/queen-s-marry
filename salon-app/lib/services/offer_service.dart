import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'cache_service.dart';

class OfferService {
  final ApiService _api = ApiService();

  /// Get all active offers (public endpoint)
  /// Cache-first: returns cached data instantly, then refreshes in background
  Future<List<dynamic>> getOffers({bool? isActive, bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.getOffers();
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheOffers(isActive);
        return cached;
      }
    } else {
      await CacheService.clearOffers();
    }

    try {
      var endpoint = '/offers';
      if (isActive != null) {
        endpoint += '?isActive=$isActive';
      }
      
      final response = await _api.get(endpoint, requiresAuth: false);
      
      // Backend format: { success: true, data: { offers: [...] } }
      final data = response['data'];
      List<dynamic> offers = [];
      if (data is Map && data['offers'] is List) {
        offers = List<dynamic>.from(data['offers'] as List);
      } else if (data is List) {
        offers = List<dynamic>.from(data);
      }

      if (offers.isNotEmpty) {
        await CacheService.saveOffers(offers);
      }
      
      return offers;
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      rethrow;
    }
  }

  Future<void> _fetchAndCacheOffers(bool? isActive) async {
    try {
      var endpoint = '/offers';
      if (isActive != null) endpoint += '?isActive=$isActive';
      final response = await _api.get(endpoint, requiresAuth: false);
      final data = response['data'];
      List<dynamic> offers = [];
      if (data is Map && data['offers'] is List) {
        offers = List<dynamic>.from(data['offers'] as List);
      } else if (data is List) {
        offers = List<dynamic>.from(data);
      }
      if (offers.isNotEmpty) await CacheService.saveOffers(offers);
    } catch (_) {}
  }

  /// Get offer by ID
  Future<Map<String, dynamic>> getOfferById(String offerId) async {
    try {
      final response = await _api.get('/offers/$offerId', requiresAuth: false);
      
      // Backend format: { success: true, data: { offer: {...} } }
      final data = response['data'];
      if (data is Map && data['offer'] is Map) {
        return Map<String, dynamic>.from(data['offer'] as Map);
      }
      
      // Fallback
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      
      throw Exception('Invalid offer data format');
    } catch (e) {
      debugPrint('Error fetching offer: $e');
      rethrow;
    }
  }
}
