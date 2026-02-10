import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import 'UserScreens/userTabbar.dart';
import 'login.dart';


class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ref = FirebaseDatabase.instance.ref().child("Users");

  Future<void> _signup() async {
    // ref.child("1234567").set({
    //   'name': "test",
    //   'email': "test",
    //   "role" : "user",
    //   'createdAt': DateTime.now().toString(),
    //   'lastLogin': DateTime.now().toString(),
    // }).then((value){
    //   print("ljljljljljlkjljl");
    // }).onError((error, stackTrace){
    //   print(error.toString());
    // });
    if (_isLoading) return; // prevent multiple taps
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      print("Signup started with email=$_email");

      try {
        // Create user in FirebaseAuth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _email, password: _password);
        print("FirebaseAuth user created successfully");

        User? user = userCredential.user;
        if (user == null) throw Exception("Signup failed: user is null");

        // Update display name in FirebaseAuth profile
        await user.updateDisplayName(name);
        await user.reload();
        print("Display name updated to $name");

        // Save user data in Firestore
        await ref.child(user.uid).set({
          'name': name.toString(),
          'email': _email.toString(),
          //'createdAt': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().toString(),
          'lastLogin': DateTime.now().toString(),
          "role" : "user",
          "switch": "user",
          'Profile url': "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRkPlBQtCa_whCpFFd_hq9xlaxOrZ5JAZrvHQ&s"
        });
        print("User data saved in Firestore");

        if (!mounted) return;

        // Navigate to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomTabBar(),
          ),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
          message = e.message ?? 'Signup failed.';
        }
        print("FirebaseAuthException: $message");
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        print("Generic error during signup: $e");
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
        print("Signup process completed");
      }
    } else {
      print("Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Opacity(
            opacity: 0.8,
            child: Image.asset(
              'assets/slider1.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/logo.png", height: 160, width: 160),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name
                            TextFormField(
                              decoration: _inputDecoration('Name', Icons.person)
                                  .copyWith(
                                suffixIcon:
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Lottie.asset('assets/profile.json', width: 20, height: 20),
                                ),
                              ),
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your name'
                                  : null,
                              onSaved: (value) => name = value!.trim(),
                            ),
                            const SizedBox(height: 20),

                            // Email
                            TextFormField(
                              decoration:
                              _inputDecoration('Email', Icons.email)
                                  .copyWith(
                                suffixIcon:
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Lottie.asset('assets/email.json', width: 20, height: 20),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value!.trim(),
                            ),
                            const SizedBox(height: 20),

                            // Password
                            TextFormField(
                              decoration:
                              _inputDecoration('Password', Icons.lock)
                                  .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) =>
                              value == null || value.length < 8
                                  ? 'Password must be at least 8 characters'
                                  : null,
                              onSaved: (value) => _password = value!.trim(),
                            ),
                            const SizedBox(height: 40),

                            // Sign Up button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 52, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _signup,
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Already have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
    );
  }
}
