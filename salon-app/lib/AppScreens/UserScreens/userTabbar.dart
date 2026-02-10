import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salon/AppScreens/UserScreens/userHome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_package;
import '../../providers/auth_provider.dart';
import '../../services/websocket_service.dart';
import '../../providers/services_provider.dart';
import '../../providers/courses_provider.dart';

import '../Settings.dart';
import 'AppointmentList.dart';
import 'Course Screens/CoursesScreen.dart';
import 'UserGallery.dart';

class BottomTabBar extends ConsumerStatefulWidget {
  // final String userName;
  // final String userEmail;
  // final String prfile;

  BottomTabBar({
    Key? key,
    // required this.userName, required this.userEmail,
    // required this.prfile,
  }) : super(key: key);
  @override
  ConsumerState<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends ConsumerState<BottomTabBar> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  String? role;
  String name = "", email = "", switchUser = "", profile = "";

  // WebSocket stream subscriptions
  StreamSubscription? _offersSubscription;
  StreamSubscription? _servicesSubscription;
  StreamSubscription? _coursesSubscription;

  @override
  void initState() {
    super.initState();
    loadUserData();

    // Setup WebSocket after a short delay to ensure auth provider is ready
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _setupWebSocket();
      }
    });

    _screens = [
      UserHome(
        key: ValueKey('home'),
        onRefresh: () => _refreshScreen(0),
      ), // index 0
      AppointmentsListScreen(
        key: ValueKey('appointments'),
        onRefresh: () => _refreshScreen(1),
      ), // index 1
      UserGalleryScreen(), // index 2
      CoursesScreen(
        key: ValueKey('courses'),
        onRefresh: () => _refreshScreen(3),
      ), // index 3
      SettingsScreen(), // index 4
    ];
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _offersSubscription?.cancel();
    _servicesSubscription?.cancel();
    _coursesSubscription?.cancel();
    WebSocketService().disconnect();
    super.dispose();
  }

  void _setupWebSocket() {
    final wsService = WebSocketService();
    // Note: AuthProvider is still using Provider (not Riverpod), so we use context
    final authProvider = provider_package.Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    // Listen for offers updates using stream (just log - individual screens handle refresh)
    _offersSubscription = wsService.offersUpdatedStream.listen((data) {
      if (mounted) {
        debugPrint(
          '🔄 WebSocket: Offers updated - individual screens will refresh',
        );
      }
    });

    // Listen for services updates using stream (refresh using Riverpod)
    _servicesSubscription = wsService.servicesUpdatedStream.listen((data) {
      if (mounted) {
        debugPrint('🔄 WebSocket: Services updated - refreshing via Riverpod');
        // Refresh using Riverpod provider with force refresh (active services only)
        ref.read(servicesProvider.notifier).loadServices(forceRefresh: true);
      }
    });

    // Listen for courses updates using stream (refresh using Riverpod)
    _coursesSubscription = wsService.coursesUpdatedStream.listen((data) {
      if (mounted) {
        debugPrint('🔄 WebSocket: Courses updated - refreshing via Riverpod');
        // Refresh using Riverpod provider with isActive filter (same as initial load)
        ref
            .read(coursesProvider.notifier)
            .loadCourses(isActive: true, forceRefresh: true);
      }
    });

    // Connect to WebSocket
    wsService.connect();

    // Join user room with actual user ID if available
    final user = authProvider.user;
    if (user != null && user['id'] != null) {
      final userId = user['id'].toString();
      debugPrint('👤 Joining user room with ID: $userId');
      wsService.joinUserRoom(userId);
    } else {
      debugPrint('⚠️ No user ID available, skipping user room join');
    }
  }

  Future<void> loadUserData() async {
    try {
      // Try to load from backend instead of Firebase
      // This is a placeholder - you'll need to implement proper user data fetching
      print('Loading user data...');

      // For now, set default values to prevent crashes
      setState(() {
        role = 'user';
        name = 'User';
        email = 'user@example.com';
        switchUser = '';
        profile = '';
      });
    } catch (e) {
      print('Error loading user data: $e');
      // Set defaults if error occurs
      setState(() {
        role = 'user';
        name = 'User';
        email = '';
      });
    }
  }

  void _refreshScreen(int index) {
    // Force rebuild of the screen to trigger refresh
    setState(() {
      // Recreate the screen widget to trigger initState/refresh
      switch (index) {
        case 0: // Home
          _screens[0] = UserHome(
            key: ValueKey('home_${DateTime.now().millisecondsSinceEpoch}'),
          );
          break;
        case 1: // Appointments
          _screens[1] = AppointmentsListScreen(
            key: ValueKey(
              'appointments_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
          break;
        case 3: // Courses
          _screens[3] = CoursesScreen(
            key: ValueKey('courses_${DateTime.now().millisecondsSinceEpoch}'),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex], // Display the selected tab's screen
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          // bottomLeft: Radius.circular(20),
          // bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.3),
            elevation: 0,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed, // needed for 5+ items
            selectedItemColor: Colors.pink,
            unselectedItemColor: Colors.grey,
            // showUnselectedLabels: true,
            onTap: (index) {
              if (index == _currentIndex) {
                // Same tab tapped - no action needed
                return;
              }

              setState(() {
                _currentIndex = index;
              });

              // Note: Individual screens handle their own refresh via their WebSocket listeners
              // No need to recreate entire screens - they update efficiently with setState()
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                label: "Home",
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.app_registration),
              //   label: "Signup",
              // ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.list_number),
                label: "List",
              ),

              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.photo_on_rectangle),
                label: "Gallery",
              ),

              // BottomNavigationBarItem(
              //   icon: Icon(Icons.safety_check),
              //   label: "Splash",
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: "Courses",
              ),

              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
