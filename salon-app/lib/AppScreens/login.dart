import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import 'OwnerScreens/OwnerTabbar.dart';
import 'UserScreens/userTabbar.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLocked = false;
  int _failedAttempts = 0;
  Timer? _lockTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _login() async {
    // 1. Handle Account Lockout with better UX
    if (_isLocked) {
      HapticFeedback.heavyImpact(); // Physical feedback for user
      _showCustomSnackBar(
        message: 'Account temporarily locked. Please wait 30 seconds.',
        isError: true,
        icon: Icons.lock_clock_outlined,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        final userData = authProvider.user;
        String role = 'user';

        if (userData != null) {
          role = userData['role'] is Map
              ? (userData['role']?['name']?.toString() ?? 'user')
              : (userData['role']?.toString() ?? 'user');
        }

        if (!mounted) return;

        // 2. Success Feedback before transition
        _showCustomSnackBar(
          message: 'Welcome back, Queen!',
          isError: false,
          icon: Icons.auto_awesome,
        );

        // Brief delay so user sees the success state
        await Future.delayed(const Duration(milliseconds: 500));

        // Initialize push notifications (Gatekeeper inside excludes guests)
        PushNotificationService().initialize();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => (role == 'admin' || role == 'owner')
                ? OwnerBottomTabBar()
                : BottomTabBar(),
          ),
          (route) => false,
        );
      } catch (e) {
        _failedAttempts++;
        HapticFeedback.vibrate(); // Vibrate on error

        if (_failedAttempts >= 3) {
          setState(() => _isLocked = true);
          _lockTimer = Timer(const Duration(seconds: 30), () {
            if (mounted) setState(() => _isLocked = false);
          });
        }

        if (mounted) {
          _showCustomSnackBar(
            message: e.toString().contains('401')
                ? 'Invalid email or password'
                : 'Login failed. Try again.',
            isError: true,
            icon: Icons.error_outline,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 3. Helper Method for Professional SnackBars
  void _showCustomSnackBar({
    required String message,
    required bool isError,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade400
            : const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: size.height * 0.32,
              child: const WaveHeaderPainterWidget(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/logo.png', height: 110),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          controller: _emailController,
                          hint: "Email Address",
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          controller: _passwordController,
                          hint: "Password",
                          isPassword: true,
                        ),
                        const SizedBox(height: 25),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFE91E63),
                              )
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon ?? Icons.lock_outline,
          color: const Color(0xFFE91E63),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFFF1F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SignupScreen()),
          ),
          child: const Text(
            "Signup",
            style: TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class WaveHeaderPainterWidget extends StatelessWidget {
  const WaveHeaderPainterWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: HeaderPainter());
  }
}

class HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF48FB1), Color(0xFFE91E63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    Path path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.65,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
