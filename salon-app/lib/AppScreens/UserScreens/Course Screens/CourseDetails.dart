import 'dart:ui';
import 'package:flutter/material.dart';
import 'CourseApplyScreen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({super.key, required this.course});

  static const Color brandPink = Color(0xFFFF0068);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parallax-style Image Header
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: course['image'].toString().startsWith('http') 
                        ? NetworkImage(course['image']) 
                        : AssetImage(course['image']) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent, const Color(0xFFFBFBFD)],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course["title"], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      const SizedBox(height: 12),
                      _buildInfoBadges(),
                      const SizedBox(height: 32),
                      const Text("Curriculum", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _buildSubjectsWrap(),
                      const SizedBox(height: 32),
                      const Text("About Course", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(course["description"], style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6), height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Glass Back Button
          _buildGlassBackButton(context),
          // Floating Action Button
          _buildApplyBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildInfoBadges() {
    return Row(
      children: [
        _badge(Icons.timer_outlined, course["duration"]),
        const SizedBox(width: 12),
        _badge(Icons.payments_outlined, "PKR ${course["price"]}"),
      ],
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: brandPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: brandPink),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSubjectsWrap() {
    final List subjects = course['subjects'] ?? [];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: subjects.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Text(s.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildGlassBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyBottomBar(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPink,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: brandPink.withOpacity(0.5),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyFormScreen(course: course["title"]))),
        child: const Text("Enroll in Academy", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}