import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/appointment_service.dart';
import '../../services/websocket_service.dart';

class AppointmentsListScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const AppointmentsListScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  _AppointmentsListScreenState createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<dynamic> _appointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _setupWebSocket();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupWebSocket() {
    final wsService = WebSocketService();

    // Listen to both singular and plural appointment events
    wsService.appointmentCreatedStream.listen((data) {
      if (mounted) {
        debugPrint('📅 Appointment created: $data');
        _loadAppointments(silent: true);
      }
    });

    wsService.appointmentUpdatedStream.listen((data) {
      if (mounted) {
        debugPrint('📅 Appointment updated: $data');
        _loadAppointments(silent: true);
      }
    });

    wsService.appointmentDeletedStream.listen((data) {
      if (mounted) {
        debugPrint('📅 Appointment deleted: $data');
        _loadAppointments(silent: true);
      }
    });

    wsService.appointmentsUpdatedStream.listen((data) {
      if (mounted) {
        debugPrint('📅 Appointments updated (plural): $data');
        _loadAppointments(silent: true);
      }
    });

    // Connect to WebSocket if not already connected
    wsService.connect();
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh appointments when screen comes back into focus (but only after first load)
    if (_hasLoadedOnce && widget.onRefresh != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAppointments(); // Refresh appointments when screen becomes visible again
      });
    } else {
      _hasLoadedOnce = true;
    }
  }

  Future<void> _loadAppointments({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final appointments = await _appointmentService.getMyAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          if (!silent) _loading = false;
        });
      }
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (!silent) _loading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(
    String appointmentId,
    String serviceName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Cancel Appointment"),
        content: Text(
          "Are you sure you want to cancel your appointment for $serviceName?",
        ),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentService.cancelAppointment(
        appointmentId,
        reason: 'Cancelled by user',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Appointment cancelled successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to cancel appointment: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointment(
    String appointmentId,
    String serviceName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Appointment"),
        content: Text(
          "Are you sure you want to permanently delete your appointment for $serviceName? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentService.deleteAppointment(appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Appointment deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete appointment: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load appointments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadAppointments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _appointments.isEmpty
          ? const Center(
              child: Text(
                "No appointments booked yet.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final a = _appointments[index] as Map<String, dynamic>;
                  final serviceName =
                      a['service_name']?.toString() ?? 'Unknown Service';
                  final customerName = a['customer_name']?.toString() ?? '';
                  final date = a['appointment_date']?.toString() ?? '';
                  final time = a['appointment_time']?.toString() ?? '';
                  final phone = a['customer_phone']?.toString() ?? '';
                  final status = a['status']?.toString() ?? 'reserved';
                  final appointmentId = a['id']?.toString() ?? '';
                  final price = a['total_price']?.toString() ?? '0';

                  return Dismissible(
                    key: Key(appointmentId),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text("Delete Appointment"),
                          content: Text(
                            "Are you sure you want to permanently delete your appointment for $serviceName?",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("No"),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text("Yes, Delete"),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        await _appointmentService.deleteAppointment(
                          appointmentId,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Appointment deleted successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to delete: ${e.toString()}",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          // Reload to restore the item if delete failed
                          _loadAppointments();
                        }
                      }
                    },
                    child: Card(
                      color: Colors.transparent,
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6CBF), // pink
                              Color(0xFFFFC371), // peach
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            CupertinoIcons.calendar_today,
                            color: Colors.black,
                            size: 40,
                          ),
                          title: Text(
                            "$serviceName - $customerName",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date: $date\nTime: $time\nPhone: $phone\nPrice: PKR $price",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing:
                              (status == 'reserved' || status == 'confirmed') &&
                                  status != 'cancelled' &&
                                  status != 'completed'
                              ? TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    _cancelAppointment(
                                      appointmentId,
                                      serviceName,
                                    );
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
