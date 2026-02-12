import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/course_service.dart';

class AdminAllCandidatesScreen extends StatefulWidget {
  const AdminAllCandidatesScreen({super.key});

  @override
  State<AdminAllCandidatesScreen> createState() =>
      _AdminAllCandidatesScreenState();
}

class _AdminAllCandidatesScreenState extends State<AdminAllCandidatesScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CourseService().getAdminApplications();
      if (mounted) {
        setState(() {
          _applications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(dynamic d) {
    if (d == null) return '—';
    if (d is String) return d;
    return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(d.toString()));
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
                Color(0xFFFF6CBF),
                Color(0xFFFFC371),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadApplications,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF),
              Color(0xFFFFC371),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadApplications,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _applications.isEmpty
                      ? const Center(
                          child: Text(
                            "No candidates have applied yet.",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _applications.length,
                            itemBuilder: (context, index) {
                              final app = _applications[index];
                              final name =
                                  app['customer_name']?.toString() ?? 'Unknown';
                              final phone =
                                  app['customer_phone']?.toString() ?? '—';
                              final email =
                                  app['customer_email']?.toString() ?? 'No Email';
                              final course = app['course_title']?.toString() ?? '—';
                              final appliedAt = _formatDate(app['applied_at']);
                              final status = app['status']?.toString() ?? 'pending';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFAD0C4),
                                          Color(0xFFFDCBF1),
                                          Color(0xFFD1FDFF),
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
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Phone: $phone",
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          Text(
                                            "Email: ${email.isEmpty ? "No Email" : email}",
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          Text(
                                            "Course: $course",
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          Text(
                                            "Applied: $appliedAt",
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          if (status != 'pending')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4),
                                              child: Text(
                                                "Status: $status",
                                                style: TextStyle(
                                                  color: status == 'approved'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
