import 'package:flutter/material.dart';
import 'package:salon/AppScreens/Services/PhotoShootServices.dart';
import 'UserFacialServices.dart';
import 'UserHairServices.dart';
import 'UserMakeupServices.dart';
import 'UserMassageServices.dart';
import 'UserMehndiServices.dart';
import 'UserWaxingServices.dart';

class ServicesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {'name': 'Hair Services', 'image': 'assets/FeatherCutting.png', 'screen': HairServices()},
    {'name': 'MakeUp Services', 'image': 'assets/MakeUp.jpg', 'screen': MakeUpServices()},
    {'name': 'Mehndi Services', 'image': 'assets/Mehndi.jpg', 'screen': MehndiServices()},
    {'name': 'Shoot Services', 'image': 'assets/PhotoShoot.jpg', 'screen': ShootServices()},
    {'name': 'Waxing Services', 'image': 'assets/Waxing.jpg', 'screen': WaxingServices()},
    {'name': 'Facial Services', 'image': 'assets/FruitFacial.jpg', 'screen': FacialServices()},
    {'name': 'Massage Services', 'image': 'assets/DeepTissueMassage.jpg', 'screen': MassageServices()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Our Services",
        style:TextStyle(fontWeight: FontWeight.bold) ,),
      backgroundColor: Colors.white,),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20,top: 5, bottom: 5),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, // 2 items per row
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.0,
          ),
          itemBuilder: (context, index) {
            final service = services[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => service['screen']),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  image: DecorationImage(
                    image: AssetImage(service['image']),
                    fit: BoxFit.cover, // fill entire container
                  ),
                ),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6), // darker at bottom for text
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      service['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
