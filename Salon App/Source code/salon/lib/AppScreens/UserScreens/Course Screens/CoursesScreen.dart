import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'CourseDetails.dart';


/// GLOBAL CANDIDATES LIST (demo purpose)
List<Map<String, String>> appliedCandidates = [];


class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  final List<Map<String, dynamic>> courses = const [
    {
      "title": "Basic Level",
      "subjects": ["Hair", "Mehndi", "Massage"],
      "duration": "3 Month",
      "price": "PKR 75,000",
      "image":'assets/BasicCourse.png',
      "description": """
The Basic Level course is designed for beginners who want to start their journey in the beauty and wellness industry. 
In this 3-month program, you will learn essential skills in Hair styling, Mehndi application, and basic Massage techniques. 

Key Highlights:
• Hands-on practical sessions to master foundational skills.
• Introduction to hygiene, safety, and client care.
• Step-by-step guidance from experienced beauticians.
• Opportunity to build confidence before moving to advanced courses.
Upon completion, you will receive a certificate validating your skills in these basic beauty treatments.
"""
    },
    {
      "title": "Advance Level",
      "subjects": ["Hair", "Mehndi", "Makeup", "Waxing", "Facial", "Massage"],
      "duration": "6 Months",
      "price": "PKR 120,000",
      "image": 'assets/AdvanceCourse.png',
      "description": """
The Advance Level course is perfect for students who have basic knowledge and want to enhance their expertise. 
This 6-month program covers advanced Hair techniques, professional Makeup, Waxing, Facial treatments, and Massage. 

Key Highlights:
• Detailed theory and practical sessions for advanced techniques.
• Learn to handle diverse client requirements and preferences.
• Tips on managing a small beauty business or freelancing.
• Training on professional-grade tools and products.
By the end of this course, students will gain practical experience and a certificate that showcases their proficiency in multiple beauty treatments.
"""
    },
    {
      "title": "Professional Level",
      "subjects": ["Hair", "Mehndi", "Makeup", "Waxing", "Facial", "Massage"],
      "duration": "12 Months",
      "price": "PKR 180,000",
      "image":'assets/ProCourse.png',
      "description": """
The Pro Level course is designed for ambitious individuals aiming to become professional beauty experts. 
This 12-month comprehensive program covers every aspect of Hair, Mehndi, Makeup, Waxing, Facial, and Massage treatments. 

Key Highlights:
• Advanced techniques for all subjects, including high-end beauty treatments.
• Client management, consultation skills, and personalized service training.
• Hands-on experience with professional equipment and products.
• Guidance on starting your own salon or becoming a freelance beauty consultant.
Upon successful completion, students will receive a Pro-level certificate, preparing them for a rewarding career in the beauty industry.
"""
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Courses",
          style: TextStyle(fontWeight: FontWeight.bold),),
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
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF6CBF), // pink
                    Color(0xFFFFC371), // peach
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      course["image"],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Image.network(
                    //   course["image"],
                    //   height: 180,
                    //   width: double.infinity,
                    //   fit: BoxFit.cover,
                    // ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Price Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course["title"],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                course["price"],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Text(
                          "Duration: ${course["duration"]}",
                          style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),

                        // Subjects as chips
                        const Text(
                          "Subjects Included:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: course["subjects"]
                              .map<Widget>(
                                (subject) => Chip(
                              label: Text(subject),
                              backgroundColor: Colors.purple.shade50,
                              labelStyle:
                              const TextStyle(color: Colors.purple),
                            ),
                          )
                              .toList(),
                        ),
                        const SizedBox(height: 16),

                        // Apply button
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF0068),
                                  Color(0xFFFF5E49)
                                ], // purple → deep blue
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5), // shadow direction
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // make button transparent
                                shadowColor: Colors.transparent,     // remove default shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailScreen(course: course),
                                  ),
                                );
                              },
                              child: const Text(
                                "Apply Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )

                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

