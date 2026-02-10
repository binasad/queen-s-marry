import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../Firebase/firebase_auth.dart';


class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final  _email = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("Forget Password",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6CBF), // pink
                Color(0xFFFFC371), // peach
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF), // pink
              Color(0xFFFFC371), // peach
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
          // borderRadius: BorderRadius.only(
          //   topLeft: Radius.circular(60),
          //   topRight: Radius.circular(60),
          // ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20,right: 20),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/Password.json',
                    width: MediaQuery.of(context).size.width * 0.7,),
                SizedBox(height: 20,),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), // <-- Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),

                  child: TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        hintStyle: TextStyle(
                          color: Colors.black45,
                          fontStyle: FontStyle.italic,
                        ),
                        contentPadding: const EdgeInsets.only(
                            left: 14.0, bottom: 8.0, top: 8.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.5),
                        labelStyle: const TextStyle(color: Colors.black),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Lottie.asset('assets/email.json', width: 20, height: 20),
                        ),
                      )),
                ),
                SizedBox(height: 50,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5, // Higher value = deeper shadow
                    padding: EdgeInsets.zero, // So the gradient container sets the size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80),
                    ),
                    backgroundColor: Colors.transparent, // Make button itself transparent
                    shadowColor: Theme.of(context).colorScheme.onBackground, // Keep shadow
                  ),
                  onPressed: () {
                    if (_email.text.isNotEmpty) {
                      AuthService().ForgotPasword(context, _email.text);
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF6CBF), // pink
                          Color(0xFFFFC371), // peach
                        ],
                      ),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      width: 160,
                      child: Text(
                        "Send Email",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}