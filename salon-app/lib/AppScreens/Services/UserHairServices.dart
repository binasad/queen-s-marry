
import 'package:flutter/material.dart';

import 'HairColoring.dart';
import 'HairCutting.dart';
import 'HairTreatment.dart';

class HairServices extends StatelessWidget {
  const HairServices({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hair Services",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),),
          backgroundColor: Colors.white,
          // flexibleSpace: Container(
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.purple, Colors.pink],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //   ),
          // ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: "Hair Cutting"),
              Tab(text: "Hair Color"),
              Tab(text: "Hair Treatment"),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: TabBarView(
            children: [
              HairCutScreen(),
              HairColorScreen(),
              HairTreatmentScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
