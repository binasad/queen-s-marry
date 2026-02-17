import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:salon/AppScreens/signup.dart';
import '../utils/route_animations.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'UserScreens/userTabbar.dart';
import 'login.dart';

class LoginOption extends StatefulWidget {
  const LoginOption({super.key});

  @override
  State<LoginOption> createState() => _LoginOptionState();
}

class _LoginOptionState extends State<LoginOption> {
  bool _isSigningIn = false;
  final AuthService _authService = AuthService();
  final StorageService _storage = const StorageService();

  // --- Auth Methods ---
  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      // serverClientId = Web OAuth client ID from Firebase/Google Cloud.
      // Required for backend idToken verification. Get it from:
      // Google Cloud Console > APIs & Credentials > OAuth 2.0 Client IDs > Web client
      final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId?.isNotEmpty == true ? serverClientId : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _showError('Google sign-in could not get ID token.');
        setState(() => _isSigningIn = false);
        return;
      }
      // Send idToken to backend, get JWT tokens, save user
      final user = await _authService.googleLogin(idToken);
      if (!mounted) return;
      final authProvider = context.read<app_auth.AuthProvider>();
      authProvider.setUser(user);
      PushNotificationService().initialize();
      _navigateToHome();
    } catch (e, st) {
      debugPrint('Google Sign-In error: $e');
      debugPrint('Stack: $st');
      final msg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('PlatformException(', '')
          .replaceAll(RegExp(r', null, null\)?$'), '');
      _showError('Google login failed: $msg');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInAnonymously() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Continue as Guest?'),
        content: const Text(
          'Guest accounts are temporary. Some features like booking appointments will require you to create an account.\n\nYou can sign up anytime to save your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSigningIn = true);
    try {
      // Use backend guest login instead of Firebase anonymous auth (no DB storage)
      final user = await _authService.guestLogin();

      // Save guest status locally
      await _storage.setGuestStatus(true);

      final authProvider = context.read<app_auth.AuthProvider>();
      authProvider.setUser(user);

      print('Guest login successful: ${user['name']}');
      _navigateToHome();
    } catch (e) {
      _showError(
        'Guest login failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _navigateToHome() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => BottomTabBar()),
  );

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevents keyboard from causing overflow, keeps screen static
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF1F6), Colors.white, Color(0xFFF48FB1)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 4), // Top breathing room
                  // 2. Lottie Animation
                  Lottie.asset(
                    'assets/salon_welcome.json',
                    width: MediaQuery.of(context).size.width * 0.55,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.spa, size: 80, color: Colors.pink),
                  ),

                  const SizedBox(height: 30),

                  // 4. Circular Google Button Section
                  const Text(
                    "CONTINUE WITH",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCircularGoogleButton(
                    onTap: () => _signInWithGoogle(context),
                  ),
                  const Spacer(flex: 3), // Space between Lottie and Buttons
                  // 3. Primary Action Button
                  _buildPrimaryButton(
                    onTap: () => Navigator.of(
                      context,
                    ).push(slideFromRightRoute(const LoginScreen())),
                    label: "ALREADY REGISTERED",
                    backgroundColor: const Color(0xFFE91E63),
                  ),
                  const Spacer(flex: 2),

                  // 5. Anonymous Entry
                  TextButton(
                    onPressed: _signInAnonymously,
                    child: const Text(
                      "Continue as Guest",
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 6. Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New here? "),
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).push(slideFromRightRoute(SignupScreen())),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (_isSigningIn) ...[
            const ModalBarrier(dismissible: false, color: Colors.black12),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularGoogleButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        height: 65,
        width: 65,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFFFFE1E9), width: 1),
        ),
        child: Image.asset("assets/Icongoogle.png"),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onTap,
    required String label,
    required Color backgroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          shadowColor: Colors.pink.withOpacity(0.3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
