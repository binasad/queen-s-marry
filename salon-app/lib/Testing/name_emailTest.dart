import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class nameTest extends StatelessWidget {
  final String userName;
  final String userEmail;

  const nameTest({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $userName!',
              style: TextStyle(fontSize: 24),
            ),
            Text('Email : , $userEmail!',
                style: TextStyle(fontSize: 24))
          ],
        ),
      ),
    );
  }
}
