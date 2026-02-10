import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Manager/AppointmentManager.dart';
import '../../Manager/NotificationManager.dart';

class AdminAppointmentsListScreen extends StatefulWidget {
  const AdminAppointmentsListScreen({Key? key}) : super(key: key);

  @override
  _AdminAppointmentsListScreenState createState() => _AdminAppointmentsListScreenState();
}

class _AdminAppointmentsListScreenState extends State<AdminAppointmentsListScreen> {
  @override
  Widget build(BuildContext context) {
    final appointments = AppointmentManager.appointments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "All Appointments",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6CBF), // pink
                Color(0xFFFFC371), // peach
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF), // pink
              Color(0xFFFFC371), // peach
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
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
          child: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: appointments.isEmpty
                ? const Center(
              child: Text(
                "No appointments booked yet.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
                : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final a = appointments[index];
                return Card(
                  color: Colors.transparent,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFAD0C4), // pastel peach
                          Color(0xFFFDCBF1), // light pink
                          Color(0xFFD1FDFF), // sky blue
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Approve Button
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _confirmAction(context, index, "approve");
                            },
                            child: const Text(
                              "Approve",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ❌ Cancel Button
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _confirmAction(context, index, "cancel");
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, int index, String action) {
    final appointment = AppointmentManager.appointments[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("${action == "approve" ? "Approve" : "Cancel"} Appointment"),
        content: Text(
            "Are you sure you want to ${action == "approve" ? "approve" : "cancel"} this appointment?"),
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

              // ✅ Add Notification
              NotificationManager.addNotification(
                  "Your appointment for '${appointment.serviceName}' on ${appointment.date} at ${appointment.time} has been ${action == "approve" ? "approved ✅" : "cancelled ❌"}");

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
