import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createAppointment({
    required String serviceId,
    required String appointmentDate,
    required String appointmentTime,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? expertId,
    String? notes,
    bool payNow = false,
    String? paymentMethod,
  }) async {
    final response = await _api.post('/appointments', {
      'serviceId': serviceId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      if (expertId != null) 'expertId': expertId,
      if (notes != null) 'notes': notes,
      'payNow': payNow,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyAppointments({String? status}) async {
    var endpoint = '/appointments/my';
    if (status != null && status.isNotEmpty) {
      endpoint += '?status=$status';
    }

    final response = await _api.get(endpoint, requiresAuth: true);
    // Backend format: { success: true, data: { appointments: [...] } }
    final data = response['data'];
    if (data is Map && data['appointments'] is List) {
      return List<dynamic>.from(data['appointments'] as List);
    }
    // Fallback (if API ever returns a bare list)
    if (data is List) return List<dynamic>.from(data);
    return const [];
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    // Backend expects reason in body for DELETE /appointments/:id/cancel
    await _api.delete(
      '/appointments/$appointmentId/cancel',
      data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }

  Future<void> deleteAppointment(String appointmentId) async {
    // Permanent delete (admin only)
    await _api.delete('/appointments/$appointmentId');
  }

  Future<Map<String, dynamic>> getAllAppointments({
    int page = 1,
    int limit = 10,
    String? status,
    String? paymentStatus,
  }) async {
    var endpoint = '/appointments?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';
    if (paymentStatus != null) endpoint += '&paymentStatus=$paymentStatus';

    final response = await _api.get(endpoint);
    // Backend format: { success: true, data: { appointments: [...], pagination: {...} } }
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'appointments': [], 'pagination': {}};
  }

  Future<Map<String, dynamic>> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final response = await _api.put('/appointments/$appointmentId/status', {
      'status': status,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markAsPaid(
    String appointmentId,
    String paymentMethod,
  ) async {
    final response = await _api.put('/appointments/$appointmentId/pay', {
      'paymentMethod': paymentMethod,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/dashboard/stats');
    return response['data'] as Map<String, dynamic>;
  }
}
