// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:salon/OwnerScreens/OwnerHome.dart';
// import 'package:salon/UserScreens/userHome.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storge;
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ref = FirebaseDatabase.instance.ref().child("Users");
//   /// SIGN UP with name, email, password
//   Future<void> signUp(BuildContext context, String name, String email, String password) async {
//     try {
//       ref.child("1234567").set({
//         'name': name,
//         'email': email,
//         "role" : "user",
//         'createdAt': DateTime.now().toString(),
//         'lastLogin': DateTime.now().toString(),
//       }).then((value){
//         print("ljljljljljlkjljl");
//       }).onError((error, stackTrace){
//         print(error.toString());
//       });
//       // //UserCredential credential =
//       // await _auth.createUserWithEmailAndPassword(
//       //   email: email,
//       //   password: password,
//       // ).then((value) async {
//       //   // Save user in Firestore with name + email
//       //   ref.child(value.user!.uid.toString()).set({
//       //     'name': name,
//       //     'email': email,
//       //     "role" : "user",
//       //     'createdAt': DateTime.now(),
//       //     'lastLogin': DateTime.now(),
//       //   }).then((value){
//       //     // Navigate after signup
//       //     Navigator.pushReplacement(
//       //       context,
//       //       MaterialPageRoute(
//       //         builder: (context) => UserHome(userName: name, userEmail: email),
//       //       ),
//       //     );
//       //
//       //   }).onError((error, stackTrace){});
//       // }).onError((error, stackTrace){
//       //
//       // });
//
//       // User? user = credential.user;
//       // if (user == null) throw Exception('User not created');
//
//       // String uid = user.uid;
//
//
//
//
//     } catch (e) {
//       // print('Signup error: $e');
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('Signup failed: ${e.toString()}')),
//       // );
//     }
//   }
//
//   /// SIGN IN with email, password
//   Future<void> signIn(BuildContext context, String email, String password) async {
//     try {
//       UserCredential credential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       User? user = credential.user;
//       if (user == null) throw Exception('User not found');
//
//       String uid = user.uid;
//
//       // Get user info from Firestore
//       DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
//       String userName;
//       String userEmail = user.email ?? email;
//
//       if (doc.exists) {
//         userName = doc['name'] ?? 'Guest';
//         // Update last login
//         await _firestore.collection('users').doc(uid).update({
//           'lastLogin': DateTime.now(),
//         });
//       } else {
//         // If not found in Firestore, create basic record
//         userName = 'Guest';
//         await _firestore.collection('users').doc(uid).set({
//           'name': userName,
//           'email': userEmail,
//           'createdAt': DateTime.now(),
//           'lastLogin': DateTime.now(),
//         });
//       }
//
//       // Navigate based on email
//       if (email.toLowerCase() == 'admin@merryqueen.com') {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => OwnerHome(userName: userName, userEmail: userEmail)),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => UserHome(userName: userName, userEmail: userEmail)),
//         );
//       }
//     } catch (e) {
//       print('Login error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login failed: ${e.toString()}')),
//       );
//     }
//   }
// }
