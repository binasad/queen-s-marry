import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'AppScreens/OwnerScreens/OwnerTabbar.dart';
import 'AppScreens/UserScreens/userTabbar.dart';
import 'AppScreens/introSlider.dart';
import 'Firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),

    );
  }
}



class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? role;
  String name = "", email = "", switchUser = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final snap = await FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (mounted) {
      setState(() {
        role = snap.child('role').value.toString();
        name = snap.child('name').value.toString();
        email = snap.child('email').value.toString();
        switchUser = snap.child("switch").value.toString();


        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (role == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (role == "user") {
        if (switchUser =="user"){
          return BottomTabBar( );
        }else if (switchUser == "owner"){
           return OwnerBottomTabBar();
        }
        return BottomTabBar();
      } else if (role == "admin") {
        if (switchUser == "admin"){
          return OwnerBottomTabBar();
        }else //if(switchUser == "user")
        {
          return BottomTabBar();
        }

      }else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      return OnboardingScreen();
    }
  }
}

