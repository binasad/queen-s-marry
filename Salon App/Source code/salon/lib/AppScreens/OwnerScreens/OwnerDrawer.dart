import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salon/AppScreens/OwnerScreens/OwnerAppointmentList.dart';
import 'package:salon/AppScreens/UserScreens/Course%20Screens/CourseAppliedList.dart';
import 'package:salon/AppScreens/OwnerScreens/OwnerCourseAppliedList.dart';
import 'package:salon/AppScreens/about.dart';
import '../ChangePassword.dart';
import '../PersonalInfo.dart';
import '../UserScreens/AppointmentList.dart';
import '../UserScreens/userTabbar.dart';
import '../login.dart';
import 'OwnerDashboard.dart';
import 'OwnerHome.dart';


class OwnerDrawer extends StatefulWidget {
  const OwnerDrawer({Key? key}) : super(key: key);

  @override
  State<OwnerDrawer> createState() => _OwnerDrawerState();
}

class _OwnerDrawerState extends State<OwnerDrawer> {
  final ref = FirebaseDatabase.instance.ref().child('Users');
  String? role;
  String name = "", email = "", switchUser = "", profile = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
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
    return name.isNotEmpty
        ? Drawer(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withOpacity(0.1)),
                    ),
                    DrawerHeader(
                      // decoration: BoxDecoration(color: Colors.pink[50]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.pink,
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(email),
                        ],
                      ),
                    ),

                  ],
                ),
                _drawerItem(
                  context,
                  icon: CupertinoIcons.person,
                  title: "Profile",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserPersonalInfo()),
                  ),
                ),

                _drawerItem(
                  context,
                  icon: CupertinoIcons.home,
                  title: "User Home",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BottomTabBar()),
                  ),
                ),

                _drawerItem(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: "Dashboard",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OwnerDashboardScreen()),
                  ),
                ),

                _drawerItem(
                  context,
                  icon: CupertinoIcons.calendar_today,
                  title: "Appointments",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminAppointmentsListScreen()),
                  ),
                ),

                _drawerItem(
                  context,
                  icon: CupertinoIcons.lock,
                  title: "Change Password",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                  ),
                ),


                _drawerItem(
                  context,
                  icon: Icons.school_outlined,
                  title: "Applied Candidates",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>AdminAllCandidatesScreen()),
                  ),
                ),

                _drawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: "About",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen()),
                  ),
                ),



                // _drawerItem(
                //   context,
                //   icon: CupertinoIcons.settings,
                //   title: "Settings",
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (_) => SettingsScreen()),
                //   ),
                // ),

                const Divider(),
                _drawerItem(
                  context,
                  icon: Icons.swap_horiz,
                  title: "Switch to User Mode",
                  iconColor: Colors.orange,
                  onTap: () {


                   ref
                        .child(FirebaseAuth.instance.currentUser!.uid)
                        .update({'switch': "user"})
                        .then((value)  {

                     Navigator.pop(context);
                        });
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(
                       builder: (_) => BottomTabBar(),
                     ), // Replace with your Owner screen
                   );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                        content: Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance
                                  .signOut()
                                  .then((value) {
                                    if (role == 'user'){
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  }})
                                  .onError((error, stack) {
                                    print(error.toString());
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                            ),
                            child: Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        : Center(child: CircularProgressIndicator());
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color iconColor = Colors.pink,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) onTap();
      },
    );
  }
}
