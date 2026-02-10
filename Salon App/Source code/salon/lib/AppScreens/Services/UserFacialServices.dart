import 'package:flutter/material.dart';
import 'FacialService.dart';
import 'FacialTreatment.dart';


class FacialServices extends StatelessWidget {
  const FacialServices({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Facial Services",
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
              Tab(text: "Facial"),
              Tab(text: "Treatment"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: TabBarView(
            children: [
              FacialService(),
              FacialTreatment(),
            ],
          ),
        ),
      ),
    );
  }
}
