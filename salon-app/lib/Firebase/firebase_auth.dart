import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  void ForgotPasword(BuildContext context, String Email) async {
    try {
      _auth.sendPasswordResetEmail(email: Email).then((value) {
        // Get.snackbar("Check Your Email",Email.toString(),
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                "Chack your email.",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      });
    } catch (error) {
      print(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              error.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
    }
  }

  // Improved forgot password method with better error handling
  Future<void> sendPasswordResetEmail(
    BuildContext context,
    String email,
  ) async {
    try {
      if (email.isEmpty) {
        _showErrorSnackbar(context, 'Please enter your email address');
        return;
      }

      // Try-And-Catch approach: Attempt to send reset email
      // Don't check if user exists first - prevents user enumeration
      await _auth.sendPasswordResetEmail(email: email);

      // ✅ Success: Email sent (or silently handled if account doesn't exist)
      _showSuccessSnackbar(
        context,
        'If an account exists with this email, you will receive a password reset link.\n\nPlease check your email and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      _handlePasswordResetError(context, e);
    } catch (e) {
      _showErrorSnackbar(
        context,
        'An unexpected error occurred. Please try again.',
      );
      debugPrint('Password reset error: ${e.toString()}');
    }
  }

  void _handlePasswordResetError(
    BuildContext context,
    FirebaseAuthException e,
  ) {
    String message = 'An error occurred. Please try again.';

    switch (e.code) {
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      default:
        // Generic message to prevent user enumeration
        message = 'An error occurred. Please try again.';
    }

    _showErrorSnackbar(context, message);
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFFB71C1C),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // This is for creating a new user
  Future<User?> createUserWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
    String name,
  ) async {
    try {
      await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) {
            final uid = value.user!.uid.toString();

            final ref = FirebaseDatabase.instance.ref().child("Users");
            ref
                .child(uid)
                .set({
                  'uid': uid,
                  'email': email,
                  'name': name, // Store name as well
                  'profile':
                      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT58-VVT8Wch6ligqL9BVGs4hHtZ2ChZeURvA&s",
                })
                .then((value) async {
                  String url;
                  final snap = await FirebaseDatabase.instance
                      .ref()
                      .child('Users')
                      .child(FirebaseAuth.instance.currentUser!.uid)
                      .get();

                  url = await snap.child('profile').value.toString();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          'User Registered Successfully!!!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                })
                .onError((error, stackTrace) {
                  // auth.currentUser!.delete();
                  // Get.snackbar("Something went wrong",error.toString());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          "Invalid Credentials!!!",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      backgroundColor: Color(0xFFB71C1C),
                    ),
                  );
                });
          })
          .onError((error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(
                  child: Text(
                    "Your Account is already register.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                backgroundColor: Color(0xFFB71C1C),
              ),
            );
          });

      final auth = FirebaseAuth.instance;
    } catch (e) {
      log('Something went wrong: $e');
    }
    return null;
  }

  // This is for logging in a user
  Future<User?> loginUserWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) async {
            String name;
            String url;
            String uid;
            final snap = await FirebaseDatabase.instance
                .ref()
                .child('Users')
                .child(value.user!.uid)
                .get();
            name = await snap.child('name').value.toString();
            uid = await snap.child('uid').value.toString();
            url = await snap.child('profile').value.toString();
            // Saving user information if it doesn't exist

            // await _firestore.collection("Users").doc(uid).set({
            //   'uid': uid,
            //   'email': email,
            // });
          })
          .onError((error, stackTrace) {
            print(error.toString());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(
                  child: Text(
                    "Invalid Credentials",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                backgroundColor: Color(0xFFB71C1C),
              ),
            );
          });
    } catch (e) {
      // log('Something went wrong: $e');
    }
    return null;
  }
}
