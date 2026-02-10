import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'loginOption.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 3 seconds then navigate to Login
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginOption()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Opacity(
            opacity: 0.8,
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // BackdropFilter(
          //   filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // control blur strength
          //   child: Container(
          //     color: Colors.white.withOpacity(0.5), // transparent layer to apply blur
          //   ),
          // ),
          Container(

          // decoration: const BoxDecoration(
          //   gradient: LinearGradient(
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //     colors: [
          //       Color(0xFFF9D7F6),
          //       Color(0xFFD3EDDB),
          //     ],
          //   ),
          // ),

          child: Center(
            child: Column(
        mainAxisSize: MainAxisSize.min,
              children: [


                // Lottie.asset(
                //   'assets/WomanHair.json',
                //   width: 250,
                //   height: 250,
                //   // width: MediaQuery.of(context).size.width * 0.4,
                //   // height: MediaQuery.of(context).size.height * 0.4,
                //   // fit: BoxFit.contain,
                // ),
                Image.asset("assets/logo.png"),
                const SizedBox(height: 20),
                const Text(
                  'Marry Queens',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic
                  ),
                ),
                Text("Beauty Salon",
                style: TextStyle(fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic),)
              ],
            ),

          ),
        ),
    ],
      ),
    );
  }
}

