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
import 'UserScreens/FavoritesScreen.dart';
import 'UserScreens/MyReviewsScreen.dart';

import 'about.dart';

import 'introSlider.dart';

import '../services/user_service.dart';

import '../services/auth_service.dart';

import '../providers/auth_provider.dart';

import '../utils/error_handler.dart';

import '../utils/guest_guard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color brandPink = Color(0xFFFF0068);
  String? role;
  String name = "", email = "", profile = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // --- Logic Handlers ---

  Future<void> loadUserData() async {
    try {
      final data = await UserService().getProfile();
      final user = data['user'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          name = user?['name']?.toString() ?? 'User';
          email = user?['email']?.toString() ?? '';
          profile = user?['profile_image_url']?.toString() ?? '';
          final roleObj = user?['role'] as Map<String, dynamic>?;
          role = roleObj?['name']?.toString() ?? 'user';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          role = 'user';
          name = 'Guest User';
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
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FD),
        body: Center(child: CircularProgressIndicator(color: brandPink)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  if (email.isNotEmpty)
                    Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                ],
              ),
            ),
          ),

          // Settings List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionLabel("ACTIVITY"),
                _buildGroup([
                  _SettingsTile(
                    icon: CupertinoIcons.calendar,
                    title: "My Appointments",
                    onTap: GuestGuard.guardAction(
                      context,
                      () async {
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsListScreen()));
                      },
                      actionDescription: 'view and manage your appointments',
                    ) ?? () {},
                  ),
                  _SettingsTile(
                    icon: Icons.favorite_outline,
                    title: "My Favorites",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.rate_review_outlined,
                    title: "My Reviews",
                    onTap: GuestGuard.guardAction(
                      context,
                      () async => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
                      actionDescription: 'view reviews',
                    ) ?? () {},
                  ),
                ]),

                const SizedBox(height: 24),
                _buildSectionLabel("PREFERENCES"),
                _buildGroup([
                  _SettingsTile(
                    icon: CupertinoIcons.lock,
                    title: "Security & Password",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.share,
                    title: "Share with Friends",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShareWithFriends())),
                  ),
                ]),

                const SizedBox(height: 24),
                _buildSectionLabel("SUPPORT"),
                _buildGroup([
                  _SettingsTile(
                    icon: Icons.support_agent,
                    title: "Help & Support",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSalonScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: "FAQ's",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
                  ),
                  // Added the About Us tile back here
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: "About Us",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())),
                  ),
                ]),

                const SizedBox(height: 40),
                _buildLogoutTile(),
                const SizedBox(height: 20),
                Center(child: Text("App Version 1.0.4", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: brandPink.withOpacity(0.1), width: 4)),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
        child: profile.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildEditButton() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPersonalInfo())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: brandPink, borderRadius: BorderRadius.circular(20)),
        child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.1)),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildLogoutTile() {
    return InkWell(
      onTap: () => _showLogoutConfirm(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.1))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Text("Logout Session", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to end your session?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLogout();
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFF0068).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFFF0068), size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}