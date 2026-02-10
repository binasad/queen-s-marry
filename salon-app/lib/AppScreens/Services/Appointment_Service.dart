import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  /// Creates a new appointment
  /// Expects appointmentTime in "HH:mm" format (e.g., "13:00")
  /// Expects appointmentDate in "YYYY-MM-DD" format
  Future<void> createAppointment({
    required String serviceId,
    required String appointmentDate,
    required String appointmentTime,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required bool payNow,
  }) async {
    // Constructing the payload
    final Map<String, dynamic> data = {
      'serviceId': serviceId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'payNow': payNow, // Backend expects Boolean
    };

    // 💡 CRITICAL DEBUG: Check this output in your VS Code/Android Studio console!
    // If it shows "1:00 pm" here, the error is in the Screen logic.
    // If it shows "13:00" here but still fails, the error is in the Backend validator.
    debugPrint("🚀 OUTGOING PAYLOAD: $data");

    try {
      await _api.post('/appointments', data);
    } catch (e) {
      debugPrint("❌ API Error in AppointmentService: $e");
      rethrow;
    }
  }

  // You can add fetchAppointments or cancelAppointment methods here later
}