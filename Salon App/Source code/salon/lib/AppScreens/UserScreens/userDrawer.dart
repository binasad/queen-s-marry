import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salon/AppScreens/UserScreens/Course%20Screens/CoursesScreen.dart';
import 'package:salon/AppScreens/UserScreens/UserNotifications.dart';
import 'Course Screens/CourseAppliedList.dart';
import '../ChangePassword.dart';
import '../OwnerScreens/OwnerTabbar.dart';
import '../PersonalInfo.dart';
import '../about.dart';
import '../login.dart';
import 'AppointmentList.dart';

class UserDrawer extends StatelessWidget {
  final String userName, userEmail,role, switchUser ;


  UserDrawer({Key? key, required this.userName, required this.userEmail,
    required this.role, required this.switchUser,}) : super(key: key);
  final ref = FirebaseDatabase.instance.ref().child('Users');

  @override
  Widget build(BuildContext context) {
    return userName.isNotEmpty ? Drawer(
      backgroundColor: Colors.white.withOpacity(0.8),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
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
                      style: TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
    ]
          ),

          // Navigation Items
          ListTile(
            leading: Icon(CupertinoIcons.person, color: Colors.pink),
            title: Text("Profile",style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        UserPersonalInfo()),
              );
            },
          ),

          ListTile(
            leading: Icon(CupertinoIcons.home, color: Colors.pink),
            title: Text("Owner Home",style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        OwnerBottomTabBar()),
              );
            },
          ),





          ListTile(
            leading: const Icon(CupertinoIcons.calendar_today, color: Colors.pink,),
            title: Text("Notifications",style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(CupertinoIcons.lock, color: Colors.pink,),
            title: Text("Change Password",style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.pink,),
            title: Text("About",style: TextStyle(fontWeight: FontWeight.bold),),
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

          // Switch to Owner button
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.orange),
            title: const Text("Switch to Owner",style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              if (role == "user"){
                ref.child(FirebaseAuth.instance.currentUser!.uid).update({'switch': "owner"}).then((value){
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => OwnerBottomTabBar()), // Replace with your Owner screen
                  );
                });

              }else if (role == 'admin'){
                ref.child(FirebaseAuth.instance.currentUser!.uid).update({'switch': "admin"}).then((value){
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => OwnerBottomTabBar()), // Replace with your Owner screen
                  );
                });
              }

            },
          ),

          // Logout
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text("Logout", style: TextStyle(color: Colors.red)),
                  content: Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel")),
                    ElevatedButton(
                        onPressed: () async {
                         await FirebaseAuth.instance.signOut().then((value){
                           Navigator.pop(context);
                           Navigator.pushReplacement(
                             context,
                             MaterialPageRoute(builder: (context) => LoginScreen()),
                           );
                         }).onError((error, stack){
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
                        )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ): Center(
      child: CircularProgressIndicator(),
    );
  }
}
