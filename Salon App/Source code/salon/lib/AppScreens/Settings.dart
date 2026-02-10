import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ChangePassword.dart';
import 'Contact.dart';
import 'FAQs.dart';
import 'PersonalInfo.dart';
import 'ShareWithFriends.dart';
import 'UserScreens/AppointmentList.dart';
import 'about.dart';
import 'login.dart';

class SettingsScreen extends StatefulWidget {
  // final String userName;
  // final String userEmail, profile;

  const SettingsScreen({
    Key? key,
    // required this.userName,
    // required this.userEmail,
    // required this.profile,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? role;
  String name = "", email = "", switchUser = "",profile = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // no logged-in user

    final snap = await FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(user.uid)
        .get();

    if (!snap.exists) {
      // User data not found in Realtime Database
      return;
    }

    if (mounted) {
      setState(() {
        role = snap.child('role').value?.toString() ?? '';
        name = snap.child('name').value?.toString() ?? '';
        email = snap.child('email').value?.toString() ?? '';
        switchUser = snap.child("switch").value?.toString() ?? '';
        profile = snap.child('Profile url').value?.toString() ?? '';
        // If your DB key is "profileUrl", change it here to match
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return profile.isNotEmpty ? Scaffold(

      body: Stack(
        children:[
          Opacity(
            opacity: 0.99,
            child:
            Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9), // control blur strength
            child: Container(
              color: Colors.white.withOpacity(0.1), // transparent layer to apply blur
            ),
          ),
          Container(

          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20,top: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green[200],
                      // child: Text(
                      //   userName.isNotEmpty ? userName[0].toUpperCase() : '',
                      //   style: TextStyle(fontSize: 28, color: Colors.grey.shade200),
                      // ),
                      child: ClipOval(
                        child: Image.network(profile,
                            fit: BoxFit.cover,
                            width: 90, // diameter = radius * 2
                            height: 90,
                          // جب image لوڈ ہو رہی ہو
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                            );
                          },
                          // جب error آئے
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return Image.asset("assets/profile.jpg",
                                fit: BoxFit.cover,
                                width: 90, // diameter = radius * 2
                                height: 90,
                            );
                          },
                        ),
                        // Image.asset(
                        //   "assets/profile.jpg",
                        //   fit: BoxFit.cover,
                        //   width: 90, // diameter = radius * 2
                        //   height: 90,
                        // ),
                      ),
                    ),

                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(email,
                            style: TextStyle(fontSize: 16,color: Colors.grey[600],fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 40,
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFD6C57),
                            Color(0xFFFE9554)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30), // adjust the radius as needed
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3), // optional shadow
                          ),
                        ],
                      ),

                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UserPersonalInfo()),
                          );
                        },
                        child: const Text("Edit Profile",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20,),
              Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16), // adjust the radius as needed
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3), // optional shadow
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ProfileTile(
                          icon: CupertinoIcons.calendar,
                          title: "My Appointments",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentsListScreen(),
                              ),
                            );
                          },
                        ),


                        ProfileTile(
                          icon: CupertinoIcons.lock,
                          title: "Change Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  )

              ),


              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16), // adjust the radius as needed
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3), // optional shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ProfileTile(
                      //   icon: Icons.rate_review,
                      //   title: "My Reviews",
                      //   onTap: () {
                      //     // Navigate to reviews
                      //   },
                      // ),
                      ProfileTile(
                        icon: CupertinoIcons.location,
                        title: "Saved Addresses",
                        onTap: () {
                          // Navigate to address management
                        },
                      ),
                      ProfileTile(
                        icon: Icons.rate_review_outlined,
                        title: "My Reviews",
                        onTap: () {
                          // Navigate to reviews
                        },
                      ),
                      // ProfileTile(
                      //   icon: CupertinoIcons.settings,
                      //   title: "Settings",
                      //   onTap: () {
                      //     Navigator.push(
                      //       context, MaterialPageRoute(
                      //       builder: (_) => SettingsScreen(),),
                      //     );
                      //     },
                      // ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16), // adjust the radius as needed
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3), // optional shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ProfileTile(
                        icon: CupertinoIcons.share,
                        title: "Share With",
                        onTap: () {
                          Navigator.push(
                            context, MaterialPageRoute(
                            builder: (_) => ShareWithFriends(),),
                          );
                        },
                      ),

                      ProfileTile(
                        icon: CupertinoIcons.phone,
                        title: "Contact Salon",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ContactSalonScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                ),
              ),


              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16), // adjust the radius as needed
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3), // optional shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      ProfileTile(
                        icon: Icons.help_outline,
                        title: "FAQ's",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FAQScreen()),
                          );
                        },
                      ),

                      ProfileTile(
                        icon: Icons.info_outline,
                        title: "About Us!",
                        onTap: () {
                          Navigator.push(
                            context, MaterialPageRoute(
                            builder: (_) => AboutScreen(),),
                          );
                        },
                      ),


                    ],
                  ),

                ),
              ),


              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16), // adjust the radius as needed
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3), // optional shadow
                      ),
                    ],
                  ),
                  child: ProfileTile(
                    icon: Icons.logout,
                    title: "Logout",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text("Logout"),
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
                                child: Text("Logout")),
                          ],
                        ),
                      );
                    },
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    ): Center(child: CircularProgressIndicator());
  }
}

// Reusable Tile Widget remains the same
class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.pink),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
