import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Manager/AppointmentManager.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsListScreenState createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  @override
  Widget build(BuildContext context) {
    final appointments = AppointmentManager.appointments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: appointments.isEmpty
          ? const Center(child: Text("No appointments booked yet.",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),))
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];
          return Card(
            color: Colors.transparent,
            elevation: 4,
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                leading: const Icon(CupertinoIcons.calendar_today,
                    color: Colors.black, size: 40),
                title: Text(
                  "${a.serviceName} ---- ${a.name}",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Date: ${a.date}\nTime: ${a.time}\nPhone: ${a.phone}",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                isThreeLine: true,
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _confirmCancel(context, index);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            ),
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(backgroundColor: Colors.white,
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Yes"),
            onPressed: () {
              setState(() {
                AppointmentManager.appointments.removeAt(index);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
