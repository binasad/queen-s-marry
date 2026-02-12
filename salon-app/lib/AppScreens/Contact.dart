import 'package:flutter/material.dart';
import '../services/support_ticket_service.dart';
import '../services/user_service.dart';
import '../utils/guest_guard.dart';
import 'signup.dart';
import '../utils/route_animations.dart';

class ContactSalonScreen extends StatefulWidget {
  const ContactSalonScreen({super.key});

  @override
  State<ContactSalonScreen> createState() => _ContactSalonScreenState();
}

class _ContactSalonScreenState extends State<ContactSalonScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupportTicketService _ticketService = SupportTicketService();

  bool _isGuest = false;
  bool _loadingTickets = true;
  bool _submitting = false;
  List<dynamic> _myTickets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isGuest = await GuestGuard.isGuest();
    setState(() {
      _isGuest = isGuest;
      _loadingTickets = !isGuest;
    });
    if (!isGuest) {
      await _loadMyTickets();
    } else {
      setState(() => _loadingTickets = false);
    }
  }

  Future<void> _loadMyTickets() async {
    if (_isGuest) return;
    setState(() => _loadingTickets = true);
    try {
      final tickets = await _ticketService.getMyTickets();
      if (mounted) {
        setState(() {
          _myTickets = tickets;
          _loadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTickets = false);
      }
    }
  }

  Future<void> _submitTicket() async {
    final canProceed = await GuestGuard.canPerformAction(
      context,
      actionDescription: 'submit a support ticket',
    );
    if (!canProceed || !mounted) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message.")),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final userData = await UserService().getProfile();
      final user = userData['user'] as Map<String, dynamic>?;
      final name = user?['name']?.toString() ?? 'User';
      final email = user?['email']?.toString() ?? '';
      final phone = user?['phone']?.toString();

      await _ticketService.createTicket({
        'customerName': name,
        'customerEmail': email,
        'customerPhone': phone,
        'subject': 'Mobile App Support',
        'message': message,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Support ticket submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _messageController.clear();
        _loadMyTickets();
      }
    } catch (e) {
      if (mounted) {
        final handled = await GuestGuard.handleApiError(
          context,
          e,
          actionDescription: 'submit a support ticket',
        );
        if (mounted && !handled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to submit: ${e.toString().split('\n').first}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Guest banner
                  if (_isGuest) _buildGuestBanner(),

                  // My tickets section (registered users only)
                  if (!_isGuest) _buildMyTicketsSection(),

                  // New ticket form
                  _buildNewTicketForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create an account to submit support tickets",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(slideFromRightRoute(const SignupScreen()));
                  },
                  child: Text(
                    "Sign up now →",
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "My Tickets",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_myTickets.isNotEmpty)
              Text(
                "${_myTickets.length} ticket(s)",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingTickets)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_myTickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 40),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "No tickets yet. Submit one below!",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          ..._myTickets.map((t) => _buildTicketCard(t)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
    final status = ticket.status?.toString() ?? 'open';
    final subject = ticket.subject?.toString() ?? 'Support';
    final message = ticket.message?.toString() ?? '';
    final createdAt = ticket.createdAt?.toString();
    final response = ticket.response?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            if (createdAt != null && createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (response != null && response.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          "Response",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      response,
                      style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildNewTicketForm() {
    final isFormDisabled = _isGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isGuest ? "Submit a ticket (requires account)" : "Submit new ticket",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          maxLines: 5,
          enabled: !isFormDisabled,
          decoration: InputDecoration(
            labelText: "Your Message",
            alignLabelWithHint: true,
            hintText: isFormDisabled ? "Sign up to submit..." : "Describe your issue...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: isFormDisabled ? Colors.grey : Colors.blue,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: isFormDisabled ? Colors.grey.shade300 : Colors.grey,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: isFormDisabled ? Colors.grey.shade100 : Colors.grey.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isFormDisabled || _submitting
                ? null
                : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFD6C57),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(isFormDisabled ? "Sign up to submit" : "Send"),
          ),
        ),
      ],
    );
  }
}
