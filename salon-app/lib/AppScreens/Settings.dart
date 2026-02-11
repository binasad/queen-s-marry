import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'ChangePassword.dart';
import 'Contact.dart';
import 'FAQs.dart';
import 'PersonalInfo.dart';
import 'ShareWithFriends.dart';
import 'UserScreens/AppointmentList.dart';
import 'about.dart';
import 'introSlider.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';

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
  String name = "", email = "", profile = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      print('Settings: Loading user data...');
      final data = await UserService().getProfile();
      print('Settings: Raw data received: $data');
      final user = data['user'] as Map<String, dynamic>?;
      print('Settings: User object: $user');

      if (mounted) {
        setState(() {
          name = user?['name']?.toString() ?? 'User';
          email = user?['email']?.toString() ?? '';
          profile = user?['profile_image_url']?.toString() ?? '';
          // Optional: derive role name if needed
          final roleObj = user?['role'] as Map<String, dynamic>?;
          role = roleObj?['name']?.toString() ?? 'user';
          _isLoading = false;

          print('Settings: Set name=$name, email=$email, profile=$profile');
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      print('Error type: ${e.runtimeType}');
      if (e is ApiException) {
        print('API Error - Status: ${e.statusCode}, Message: ${e.message}');
      }
      if (mounted) {
        setState(() {
          role = 'user';
          name = 'User';
          email = '';
          profile = '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService().logout();
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 0.99,
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          Container(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green[200],
                        child: profile.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  profile,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 40,
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFD6C57), Color(0xFFFE9554)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // adjust the radius as needed
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
                              MaterialPageRoute(
                                builder: (context) => UserPersonalInfo(),
                              ),
                            );
                          },
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // adjust the radius as needed
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
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
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
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // adjust the radius as needed
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
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // adjust the radius as needed
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
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShareWithFriends(),
                              ),
                            );
                          },
                        ),

                        ProfileTile(
                          icon: Icons.support_agent,
                          title: "Help & Support",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ContactSalonScreen(),
                              ),
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
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // adjust the radius as needed
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
                              MaterialPageRoute(
                                builder: (context) => const FAQScreen(),
                              ),
                            );
                          },
                        ),

                        ProfileTile(
                          icon: Icons.info_outline,
                          title: "About Us!",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AboutScreen()),
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
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // adjust the radius as needed
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
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog first
                                  await _handleLogout();
                                },
                                child: Text("Logout"),
                              ),
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
    );
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
