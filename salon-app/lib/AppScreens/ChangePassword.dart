import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/guest_guard.dart';
import '../services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color brandPink = Color(0xFFFF0068);
  static const Color brandPeach = Color(0xFFFFC371);

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  String? _userEmail;

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      // 1. Fetch the profile data from your UserService
      final profileData = await UserService().getProfile();
      
      // 2. Extract the user object safely
      final user = profileData['user'] as Map<String, dynamic>?;

      if (mounted && user != null) {
        setState(() {
          // 3. Extract email and handle potential nulls
          // We use .toString() to ensure type safety
          _userEmail = user['email']?.toString();
          
          // Debugging log (Optional, remove for production)
          print('ChangePassword: User email loaded: $_userEmail');
        });
      }
    } catch (e) {
      // 4. Empathy-based error handling
      debugPrint('Error loading user email for password change: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not verify your email. Please try again later."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendOtp() async {
    // Check if user is a guest - guests cannot change password
    final canProceed = await GuestGuard.canPerformAction(
      context,
      actionDescription: 'change your password',
    );
    if (!canProceed) return;

    setState(() => _isSendingOtp = true);

    try {
      await AuthService().sendChangePasswordOtp();

      if (mounted) {
        setState(() {
          _otpSent = true;
          _isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification code sent to your email"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final otpCode = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otpCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the verification code")),
      );
      return;
    }

    if (otpCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification code must be 6 digits")),
      );
      return;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all password fields")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    // Validate password requirements
    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
      );
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    if (!passwordRegex.hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must contain uppercase, lowercase, number, and special character",
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().changePasswordWithOtp(
        code: otpCode,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password changed successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _otpController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _otpSent = false;
        });
      }
    } catch (e) {
      ErrorHandler.show(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Security", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Branded Top Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Lottie.asset(
                'assets/Password.json',
                height: 200,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _otpSent ? _buildVerificationStep() : _buildRequestStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text(
          "Verification Required",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          "We'll send a 6-digit verification code to:",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (_userEmail != null) ...[
          const SizedBox(height: 8),
          Text(
            _userEmail!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandPink),
          ),
        ],
        const SizedBox(height: 40),
        _buildActionButton(
          label: "Send Code",
          isLoading: _isSendingOtp,
          onPressed: _sendOtp,
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        const Text(
          "Set New Password",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 32),
        
        // Custom Styled Inputs
        _buildInputField(
          controller: _otpController,
          label: "Verification Code",
          icon: Icons.vpn_key_outlined,
          isOtp: true,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _passwordController,
          label: "New Password",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: !_showNewPassword,
          onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _confirmPasswordController,
          label: "Confirm Password",
          icon: Icons.lock_reset_rounded,
          isPassword: true,
          obscure: !_showConfirmPassword,
          onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
        ),
        
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSendingOtp ? null : _sendOtp,
          child: const Text("Didn't receive code? Resend", style: TextStyle(color: brandPink, fontWeight: FontWeight.bold)),
        ),
        
        const SizedBox(height: 32),
        _buildActionButton(
          label: "Update Password",
          isLoading: _isLoading,
          onPressed: _changePassword,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isOtp = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isOtp ? TextInputType.number : TextInputType.text,
        maxLength: isOtp ? 6 : null,
        textAlign: isOtp ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          letterSpacing: isOtp ? 8 : 0,
          fontWeight: isOtp ? FontWeight.bold : FontWeight.normal,
          fontSize: isOtp ? 20 : 15,
        ),
        decoration: InputDecoration(
          counterText: "",
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14, letterSpacing: 0),
          prefixIcon: Icon(icon, color: brandPink, size: 20),
          suffixIcon: isPassword 
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: onToggle)
            : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required bool isLoading, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: brandPink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}