import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'CourseDetails.dart';
import '../../../providers/courses_provider.dart';
import '../../../services/websocket_service.dart';
import '../../../utils/haptic_feedback.dart';
import '../../../widgets/cached_image.dart';

// GLOBAL list for demo/legacy logic
List<Map<String, String>> appliedCandidates = [];

class CoursesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;
  const CoursesScreen({super.key, this.onRefresh});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  StreamSubscription? _coursesSubscription;
  static const Color brandPink = Color(0xFFFF0068);
  static const Color premiumBg = Color(0xFFFBFBFD);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(coursesProvider.notifier).loadCourses(isActive: true);
    });
    _setupWebSocket();
  }

  @override
  void dispose() {
    _coursesSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    final wsService = WebSocketService();
    _coursesSubscription = wsService.coursesUpdatedStream.listen((_) {
      if (mounted) ref.read(coursesProvider.notifier).loadCourses(isActive: true, forceRefresh: true);
    });
    wsService.connect();
  }

  // Helper to format API data for the UI
  Map<String, dynamic> _formatCourse(Map<String, dynamic> c) {
    return {
      'id': c['id']?.toString() ?? '',
      'title': c['title']?.toString() ?? 'Elite Course',
      'duration': c['duration']?.toString() ?? 'Flexible',
      'price': c['price']?.toString() ?? '0',
      'image': c['image_url']?.toString() ?? '',
      'description': c['description']?.toString() ?? '',
      'subjects': (c['description']?.toString().contains('Subjects Included:') ?? false) 
          ? c['description'].toString().split('Subjects Included:')[1].split(',').map((e) => e.trim()).toList()
          : ['Professional Training'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesListProvider);
    final loading = ref.watch(coursesLoadingProvider);

    return Scaffold(
      backgroundColor: premiumBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              title: const Text("Our Academy", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: loading && courses.isEmpty
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : RefreshIndicator(
              color: brandPink,
              onRefresh: () async => ref.read(coursesProvider.notifier).loadCourses(isActive: true),
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 80, 20, 20),
                  itemCount: courses.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final courseData = _formatCourse(courses[index] as Map<String, dynamic>);
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _PremiumCourseCard(
                            course: courseData,
                            onTap: () {
                              HapticHelper.mediumImpact();
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(course: courseData),
                              ));
                            },
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

class _PremiumCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;

  const _PremiumCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF0068).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: CachedImageWidget(
                imageUrl: course['image'] ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(course['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                      Text("PKR ${course['price']}", style: const TextStyle(color: Color(0xFFFF0068), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(course['duration'], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}