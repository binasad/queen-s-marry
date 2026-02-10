import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salon/AppScreens/Services/userServices.dart';
import 'package:salon/AppScreens/OwnerScreens/OwnerCourseAppliedList.dart';

import '../PersonalInfo.dart';
import '../Services/UserFacialServices.dart';
import '../Services/UserHairServices.dart';
import '../Services/UserMakeupServices.dart';
import '../Services/UserMassageServices.dart';
import '../Services/UserMehndiServices.dart';
import '../Services/UserWaxingServices.dart';
import '../UserScreens/AppointmentList.dart';

class OwnerDashboardScreen extends StatefulWidget {


  const OwnerDashboardScreen({Key? key, }) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String? role;
  String name = "", email = "", switchUser = "",profile = "";

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


    setState(() {
      role = snap.child('role').value.toString();
      name = snap.child('name').value.toString();
      email = snap.child('email').value.toString();
      switchUser = snap.child("switch").value.toString();
      profile = snap.child('Profile url').value.toString();


    });

  }
  @override
  Widget build(BuildContext context) {
    return name.isNotEmpty? Scaffold(
      appBar: AppBar(
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      // drawer: OwnerDrawer(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [

            _dashboardCard(
              context,
              title: "Profile",
              icon: CupertinoIcons.person,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserPersonalInfo()),
              ),
            ),

            _dashboardCard(
              context,
              title: "Appointments",
              icon: CupertinoIcons.calendar_today,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AppointmentsListScreen()),
              ),
            ),

            _dashboardCard(
              context,
              title: "Applied Candidates",
              icon: Icons.school_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminAllCandidatesScreen()),
              ),
            ),

            _dashboardCard(
              context,
              title: "Services Screen",
              icon: Icons.face_retouching_natural,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServicesScreen()),
              ),
            ),
            //
            // _dashboardCard(
            //   context,
            //   title: "Makeup Services",
            //   icon: Icons.brush,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => MakeUpServices()),
            //   ),
            // ),
            //
            // _dashboardCard(
            //   context,
            //   title: "Mehndi Services",
            //   icon: Icons.emoji_nature,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => MehndiServices()),
            //   ),
            // ),
            // _dashboardCard(
            //   context,
            //   title: "Waxing Services",
            //   icon: CupertinoIcons.drop   ,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => WaxingServices( )),
            //   ),
            // ),
            // _dashboardCard(
            //   context,
            //   title: "Facial Services",
            //   icon: Icons.face_retouching_natural,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => FacialServices( )),
            //   ),
            // ),
            // _dashboardCard(
            //   context,
            //   title: "Massage Services",
            //   icon: Icons.self_improvement,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => MassageServices( )),
            //   ),
            // ),
          ],
        ),
      ),
    ): Center(child: CircularProgressIndicator());
  }

  Widget _dashboardCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6CBF),
              Color(0xFFFFC371)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
