import 'package:flutter/material.dart';
import '../../Manager/NotificationManager.dart';
import '../UserScreens/Course Screens/CoursesScreen.dart';

// GLOBAL CANDIDATES LIST (demo purpose)
List<Map<String, String>> appliedCandidates = [];

class AdminAllCandidatesScreen extends StatefulWidget {
  const AdminAllCandidatesScreen({super.key});

  @override
  State<AdminAllCandidatesScreen> createState() =>
      _AdminAllCandidatesScreenState();
}

class _AdminAllCandidatesScreenState extends State<AdminAllCandidatesScreen> {
  void _confirmAction(int index, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$action Application"),
        content: Text("Are you sure you want to $action this application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // close dialog
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == "Cancel" ? Colors.red : Colors.green,
            ),
            onPressed: () {
              final candidate = appliedCandidates[index];

              setState(() {
                appliedCandidates.removeAt(index);
              });

              // ✅ Add notification for user
              NotificationManager.addNotification(
                "Your application for ${candidate["course"]} has been "
                "${action == "Approve" ? "approved ✅" : "cancelled ❌"} by admin.",
              );

              Navigator.pop(ctx); // close dialog
            },
            child: Text("Yes, $action"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "All Applied Candidates",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
          child: appliedCandidates.isEmpty
              ? const Center(
                  child: Text(
                    "No candidates have applied yet.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: appliedCandidates.length,
                  itemBuilder: (context, index) {
                    final candidate = appliedCandidates[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.pink.shade200,
                              child: Text(
                                candidate["name"]![0].toUpperCase(),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            title: Text(
                              candidate["name"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phone: ${candidate["number"]}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Text(
                                  "Email: ${candidate["email"]?.isNotEmpty == true ? candidate["email"] : "No Email"}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Text(
                                  "Course: ${candidate["course"]}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Text(
                                  "Applied At: ${candidate["appliedAt"]}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _confirmAction(index, "Approve"),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Approve",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _confirmAction(index, "Cancel"),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
