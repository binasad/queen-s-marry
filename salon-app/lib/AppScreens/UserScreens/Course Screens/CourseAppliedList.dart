import 'package:flutter/material.dart';
import 'CoursesScreen.dart';
class AllCandidatesScreen extends StatefulWidget {
  const AllCandidatesScreen({super.key});

  @override
  State<AllCandidatesScreen> createState() => _AllCandidatesScreenState();
}

class _AllCandidatesScreenState extends State<AllCandidatesScreen> {
  void cancelApplication(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Application"),
        content: const Text("Are you sure you want to cancel this application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // close dialog
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              setState(() {
                appliedCandidates.removeAt(index);
              });
              Navigator.pop(ctx); // close dialog
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applied Candidates",style: TextStyle(fontWeight: FontWeight.bold),),
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
          decoration: BoxDecoration(
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
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      title: Text(
                        candidate["name"] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text("Father: ${candidate["father"]}", style: const TextStyle(color: Colors.black)),
                          Text("Phone: ${candidate["number"]}", style: const TextStyle(color: Colors.black)),
                          Text(
                            "Email: ${candidate["email"]?.isNotEmpty == true ? candidate["email"] : "No Email"}",
                            style: const TextStyle(color: Colors.black),
                          ),

                          // Text("CNIC: ${candidate["cnic"]}", style: const TextStyle(color: Colors.black)),
                          Text("Course: ${candidate["course"]}", style: const TextStyle(color: Colors.black)),
                          Text("Applied At: ${candidate["appliedAt"]}", style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () => cancelApplication(index),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
