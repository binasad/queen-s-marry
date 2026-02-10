import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:salon/AppScreens/signup.dart';

import 'ForgotPassword.dart';
import 'OwnerScreens/OwnerTabbar.dart';
import 'UserScreens/userTabbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  final _emailController = TextEditingController();
  String _password = '';
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? Role;
  String Name = '';
  String Email = "",  switchUser = '';


  // Firebase login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
        User? user = userCredential.user;

        // if (_email.toLowerCase() == 'admin@merryqueen.com') {
        //   // Admin: navigate to OwnerHome
        //   String userName = user?.displayName ?? 'ADMIN';
        //   String userEmail = user?.email ?? _email;
        //
        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) =>
        //           OwnerHome(userName: userName, userEmail: userEmail),
        //     ),
        //     (route) => false,
        //   );
        // } else {
        //   // Regular user: fetch Firestore data
        //   DocumentSnapshot userDoc = await FirebaseFirestore.instance
        //       .collection('users')
        //       .doc(userCredential.user!.uid)
        //       .get();
        //
        //   String name = userDoc.exists && userDoc['name'] != null
        //       ? userDoc['name']
        //       : 'User';
        //
        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) =>
        //           BottomTabBar(userName: name, userEmail: _email),
        //     ),
        //     (route) => false,
        //   );
        // }

        final snap = await FirebaseDatabase.instance
            .ref()
            .child('Users')
            .child(FirebaseAuth.instance.currentUser!.uid)
            .get();
        Role = await snap.child('role').value.toString();
        Name = await snap .child('name').value.toString();
        Email = await snap .child('email').value.toString();
        switchUser = snap.child("switch").value.toString();
        print(Role.toString());
        switch (Role) {
          case "user":
            {   Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>  BottomTabBar(),
              ),

                  (route) => false,
            );


            //   if (switchUser =='users'){
            //   Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) =>  BottomTabBar(),
            //     ),
            //
            //         (route) => false,
            //   );
            // }else if (switchUser == "owner"){
            //   Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) =>  OwnerDashboardScreen(),
            //     ),
            //
            //         (route) => false,
            //   );
            // }

              setState(() => _isLoading = false);
              Role = "";
              // Get.snackbar("your account is Login",EmailController.value.text );
              _passwordController.clear();
              _emailController.clear();
            }
            break;
          case "admin":
            {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OwnerBottomTabBar(),
                ),
                    (route) => false,
              );
              // if (switchUser == 'admin'){
              //   Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) =>
              //           OwnerHome(),
              //     ),
              //         (route) => false,
              //   );
              //
              // } else if (switchUser == "user"){
              //   Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) =>
              //           BottomTabBar(),
              //     ),
              //         (route) => false,
              //   );
              // }
              Role = "";
              setState(() => _isLoading = false);
              _passwordController.clear();
              _emailController.clear();


              //  Get.snackbar("your account is Login",EmailController.value.text );
            }
            break;
        }
      } on FirebaseAuthException catch (e) {
        // ... your existing error handling ...
      } finally {
        setState(() => _isLoading = false);
      }
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/logo.png", height: 160, width: 160),
                  const SizedBox(height: 16),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Lottie.asset('assets/email.json', width: 20, height: 20),
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!.trim(),
                        ),
                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!.trim(),
                        ),
                        const SizedBox(height: 40),

                        // Login button
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 52,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Signup",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgetPassword(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forget Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
