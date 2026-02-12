import 'api_service.dart';

class SupportTicket {
  final String id;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final String? assignedToName;
  final String? response;
  final String? createdAt;
  final String? resolvedAt;

  SupportTicket({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    this.assignedToName,
    this.response,
    this.createdAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      subject: json['subject'],
      message: json['message'],
      status: json['status'],
      priority: json['priority'],
      assignedToName: json['assigned_to_name'],
      response: json['response'],
      createdAt: json['created_at'],
      resolvedAt: json['resolved_at'],
    );
  }
}

class SupportTicketService {
  final ApiService _apiService = ApiService();

  /// Get current user's tickets (with status) - for Help & Support screen
  Future<List<SupportTicket>> getMyTickets() async {
    try {
      final response = await _apiService.get('/support/tickets/my');
      final data = response['data'];
      if (data is Map && data['tickets'] is List) {
        return (data['tickets'] as List)
            .map((t) => SupportTicket.fromJson(Map<String, dynamic>.from(t)))
            .toList();
      }
      return [];
    } catch (e) {
      print('SupportTicketService Error (getMyTickets): $e');
      rethrow;
    }
  }

  Future<List<SupportTicket>> getAllTickets({
    Map<String, String>? params,
  }) async {
    try {
      final response = await _apiService.get('/support/tickets');
      final tickets = response['data']['tickets'] as List;
      return tickets.map((t) => SupportTicket.fromJson(t)).toList();
    } catch (e) {
      print('SupportTicketService Error (getAll): $e');
      rethrow;
    }
  }

  Future<SupportTicket> getTicketById(String id) async {
    try {
      final response = await _apiService.get('/support/tickets/$id');
      return SupportTicket.fromJson(response['data']);
    } catch (e) {
      print('SupportTicketService Error (getById): $e');
      rethrow;
    }
  }

  Future<void> createTicket(Map<String, dynamic> ticketData) async {
    try {
      await _apiService.post('/support/tickets', ticketData);
    } catch (e) {
      print('SupportTicketService Error: $e');
      rethrow;
    }
  }

  Future<void> updateTicket(String id, Map<String, dynamic> updateData) async {
    try {
      await _apiService.post(
        '/support/tickets/$id',
        updateData,
      ); // Use post or put as per your backend
    } catch (e) {
      print('SupportTicketService Error (update): $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      await _apiService.delete('/support/tickets/$id');
    } catch (e) {
      print('SupportTicketService Error (delete): $e');
      rethrow;
    }
  }
}
