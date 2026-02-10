import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:salon/AppScreens/UserScreens/Course%20Screens/CoursesScreen.dart';
import 'package:salon/AppScreens/UserScreens/UserNotifications.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import 'Course Screens/CourseAppliedList.dart';
import '../ChangePassword.dart';
import '../PersonalInfo.dart';
import '../about.dart';
import '../login.dart';

class UserDrawer extends StatelessWidget {
  final String userName, userEmail;

  UserDrawer({Key? key, required this.userName, required this.userEmail})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return userName.isNotEmpty
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
                      decoration: BoxDecoration(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.pink,
                            child: Text(
                              userName[0],
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Navigation Items
                ListTile(
                  leading: Icon(CupertinoIcons.person, color: Colors.pink),
                  title: Text(
                    "Profile",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserPersonalInfo(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    CupertinoIcons.calendar_today,
                    color: Colors.pink,
                  ),
                  title: Text(
                    "Notifications",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(CupertinoIcons.lock, color: Colors.pink),
                  title: Text(
                    "Change Password",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.pink),
                  title: Text(
                    "About",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutScreen()),
                    );
                  },
                ),

                // ListTile(
                //   leading: const Icon(Icons.info_outline, color: Colors.pink,),
                //   title: Text("All Applied",style: TextStyle(fontWeight: FontWeight.bold),),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => AllCandidatesScreen()),
                //     );
                //   },
                // ),

                // ListTile(
                //   leading: const Icon(CupertinoIcons.settings, color: Colors.pink),
                //   title: const Text("Settings",style: TextStyle(fontWeight: FontWeight.bold),),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context, MaterialPageRoute(
                //       builder: (_) => SettingsScreen(),),
                //     );
                //   },
                // ),
                Divider(),
                // Logout
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
                              Navigator.pop(context);
                              await AuthService().logout();
                              final authProvider = provider_package.Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              }
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
}
