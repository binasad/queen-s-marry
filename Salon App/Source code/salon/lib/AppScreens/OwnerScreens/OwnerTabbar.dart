import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Settings.dart';
import '../UserScreens/AppointmentList.dart';
import 'OwnerAppointmentList.dart';
import 'OwnerDashboard.dart';
import 'OwnerGallery.dart';
import 'OwnerHome.dart';

class OwnerBottomTabBar extends StatefulWidget {
  // final String userName;
  // final String userEmail;
  // final String prfile;

  OwnerBottomTabBar({Key? key,
    // required this.userName, required this.userEmail,
    // required this.prfile,
  }) : super(key: key);
  @override
  _OwnerBottomTabBarState createState() => _OwnerBottomTabBarState();
}

class _OwnerBottomTabBarState extends State<OwnerBottomTabBar> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  String? role;
  String name = "", email = "", switchUser = "",profile = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
    _screens = [
      OwnerHome(), // index 0
      AdminAppointmentsListScreen(),      // index 1
      AdminGalleryScreen(), //index 2
      OwnerDashboardScreen(), // index 3
      SettingsScreen(),      // index 4

    ];
  }

  Future<void> loadUserData() async {
    final snap = await FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .get();


    setState(() {
      role = snap.child('role').value.toString();
      name = snap.child('name').value.toString();
      email = snap.child('email').value.toString();
      switchUser = snap.child("switch").value.toString();
      profile = snap.child('Profile url').value.toString();


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
              setState(() {
                _currentIndex = index;
              });
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
                icon: Icon(CupertinoIcons.photo_camera),
                label: "Gallery",
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_customize_outlined),
                label: "Dashboard",
              ),

              // BottomNavigationBarItem(
              //   icon: Icon(Icons.safety_check),
              //   label: "Splash",
              // ),
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
