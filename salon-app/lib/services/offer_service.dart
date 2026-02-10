import 'api_service.dart';

class OfferService {
  final ApiService _api = ApiService();

  /// Get all active offers (public endpoint)
  /// Returns offers that are active and within their date range
  Future<List<dynamic>> getOffers({bool? isActive}) async {
    try {
      var endpoint = '/offers';
      if (isActive != null) {
        endpoint += '?isActive=$isActive';
      }
      
      final response = await _api.get(endpoint, requiresAuth: false);
      
      // Backend format: { success: true, data: { offers: [...] } }
      final data = response['data'];
      if (data is Map && data['offers'] is List) {
        return List<dynamic>.from(data['offers'] as List);
      }
      
      // Fallback if API returns a flat list
      if (data is List) {
        return List<dynamic>.from(data);
      }
      
      return [];
    } catch (e) {
      print('Error fetching offers: $e');
      rethrow;
    }
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
      print('Error fetching offer: $e');
      rethrow;
    }
  }
}
