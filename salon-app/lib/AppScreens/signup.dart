import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/route_animations.dart';
import 'login.dart';
import 'EmailVerificationScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  
  String _gender = 'Female';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // --- 1. SIGNUP LOGIC (Fixed Getter Error) ---
  Future<void> _signup() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        await AuthService().register(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
          phone: _contactController.text.trim(),
          address: _addressController.text.trim(),
          gender: _gender,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          slideFromRightRoute(EmailVerificationScreen(email: email))
        );
      } catch (e) {
        ErrorHandler.show(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: size.height * 0.22, 
              child: const WaveHeaderPainterWidget(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeaderTitle(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline),
                                const SizedBox(height: 15),
                                _buildField(controller: _emailController, hint: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 15),
                                _buildField(controller: _contactController, hint: "Phone", icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                                const SizedBox(height: 15),
                                _buildField(controller: _addressController, hint: "Address", icon: Icons.location_on_outlined),
                                const SizedBox(height: 15),
                                _buildField(controller: _passwordController, hint: "Password", icon: Icons.lock_outline, isPassword: true),
                                const SizedBox(height: 25),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Gender", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                                ),
                                const SizedBox(height: 10),
                                _buildGenderToggle(),
                                const SizedBox(height: 35),
                                _buildSignupButton(),
                                const SizedBox(height: 20),
                                _buildFooter(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. HELPER METHODS (Fixed Method Not Defined Errors) ---

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text("Create Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFE91E63)),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
          : null,
        filled: true,
        fillColor: const Color(0xFFFFF1F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      validator: (val) => val == null || val.isEmpty ? "Required field" : null,
    );
  }

  Widget _buildGenderToggle() {
    return Row(
      children: ['Male', 'Female', 'Other'].map((g) {
        bool isSelected = _gender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE91E63) : const Color(0xFFFFF1F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  g,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSignupButton() {
    return _isLoading
        ? const CircularProgressIndicator(color: Color(0xFFE91E63))
        : ElevatedButton(
            onPressed: _signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
            child: const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        
        
        const Text("Already have an account? "),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacement(slideFromRightRoute(const LoginScreen())),
          child: const Text("Login", style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}