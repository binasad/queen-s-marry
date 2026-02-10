
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salon/AppScreens/PersonalInfo.dart';
import 'package:salon/AppScreens/Services/PhotoShootServices.dart';
import 'package:salon/AppScreens/UserScreens/userDrawer.dart';
import '../../Manager/ExpertManager.dart';
import '../../Manager/OfferManager.dart';
import '../Services/UserFacialServices.dart';
import '../Services/UserHairServices.dart';
import '../Services/UserMakeupServices.dart';
import '../Services/UserMassageServices.dart';
import '../Services/UserMehndiServices.dart';
import '../Services/UserWaxingServices.dart';
import '../Services/userServices.dart';
import '../Services/servicesdetails.dart';
import '../googleMap.dart';

class UserHome extends StatefulWidget {


  UserHome({Key? key, })
      : super(key: key);

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String location = "I8 Markaz, ISB";
  TextEditingController _searchController = TextEditingController();

  // filtered lists for search
  List<Map<String, String>> filteredOffers = [];
  List<Map<String, String>> filteredExperts = [];
  String? role;
  String name = "", email = "", switchUser = "",profile = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
    filteredOffers = List.from(OfferManager.offers);
    filteredExperts = List.from(ExpertManager.experts);

    _searchController.addListener(_onSearchChanged);

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



  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      filteredOffers = OfferManager.offers.where((offer) {
        return (offer["title"] ?? "").toLowerCase().contains(query) ||
            (offer["discount"] ?? "").toLowerCase().contains(query);
      }).toList();

      filteredExperts = ExpertManager.experts.where((expert) {
        return (expert["name"] ?? "").toLowerCase().contains(query) ||
            (expert["specialty"] ?? "").toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (name.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Hello, ",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400)),
                    Text("${name}",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("Welcome to Merry Queen Salon",
                    style: TextStyle(color: Colors.black, fontSize: 14)),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserPersonalInfo(),
                  ),
                );
              },
              child: ClipOval(
                child: Image.network(profile,
                  fit: BoxFit.cover,
                  width: 40, // diameter = radius * 2
                  height: 40,

                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
                  // جب error آئے
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Image.asset("assets/profile.jpg",
                      fit: BoxFit.cover,
                      width: 90, // diameter = radius * 2
                      height: 90,
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
        extendBody: true,
        extendBodyBehindAppBar: true,
      drawer: UserDrawer(userName: name, userEmail: email, role: role!, switchUser: switchUser,),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.9,
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          Container(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        children: [
                          Lottie.asset('assets/LocationPin.json', width: 40, height: 40),
                          SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => GoogleMapScreen()));
                            },
                            child: Text(location,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
                          ),
                          Spacer(),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.pink[50],
                            child: Lottie.asset('assets/Bellring.json', width: 40, height: 40),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search Salon, Specialist...",
                        prefixIcon: Icon(CupertinoIcons.search, color: Colors.pink),
                        suffixIcon: Icon(Icons.filter_list, color: Colors.pink),
                        filled: true,
                        fillColor: Color(0xFFB4FFF1),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Special Offers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("#SpecialForYou",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("See All", style: TextStyle(color: Colors.pink)),
                      ],
                    ),
                    SizedBox(height: 12),

                Container(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredOffers.length + 2, // +1 dummy, +1 add card
                    separatorBuilder: (_, __) => SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index < filteredOffers.length) {
                        // Show real offers
                        final offer = filteredOffers[index];
                        return _buildOfferCard(
                          offer["title"] ?? "",
                          offer["discount"] ?? "",
                          offer["image"] ?? "",
                          duration: offer["duration"] ?? "Limited",
                        );
                      } else if (index == filteredOffers.length) {
                        // Dummy card
                        return _buildOfferCard(
                          "Coming Soon",
                          "??%",
                          "assets/bgbg.png", // must exist in pubspec.yaml
                          duration: "TBD",
                        );
                      }
                    },
                  ),
                ),


                    SizedBox(height: 24),

                    // Services
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Services",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ServicesScreen()),
                            );
                          },
                          child: const Text("See All",
                              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),

                    Container(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => HairServices())),
                              child: _buildServiceIcon("assets/FeatherCutting.png", "Hair")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => MakeUpServices())),
                              child: _buildServiceIcon("assets/MakeUp.jpg", "MakeUp")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => MehndiServices())),
                              child: _buildServiceIcon("assets/Mehndi.jpg", "Mehndi")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => ShootServices())),
                              child: _buildServiceIcon("assets/PhotoShoot.jpg", "PhotoShoot")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => WaxingServices())),
                              child: _buildServiceIcon("assets/Waxing.jpg", "Waxing")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => FacialServices())),
                              child: _buildServiceIcon("assets/GlowFacial.jpg", "Facial")),
                          InkWell(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => MassageServices())),
                              child: _buildServiceIcon("assets/DeepTissueMassage.jpg", "Massage")),
                        ],
                      ),
                    ),
                    SizedBox(height: 24,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Our Experts",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("See All", style: TextStyle(color: Colors.pink)),
                      ],
                    ),
                    SizedBox(height: 12),

                Container(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredExperts.length + 2, // +1 dummy, +1 add card
                    separatorBuilder: (_, __) => SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index < filteredExperts.length) {
                        // Show real experts
                        final expert = filteredExperts[index];
                        return _buildExpertCard(
                          expert["name"] ?? "",
                          expert["specialty"] ?? "",
                          expert["image"] ?? "",
                        );
                      } else if (index == filteredExperts.length) {
                        // Dummy expert card
                        return _buildExpertCard(
                          " Coming Soon ",
                          " Specialty ",
                          "assets/profile.jpg", // must be in pubspec.yaml
                        );
                      }
                    },
                  ),
                ),
                    SizedBox(height: 2),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildOfferCard(String title, String discount, String imagePath,
      {String duration = "Limited"}) {
    ImageProvider backgroundImage;

    if (imagePath.startsWith('http')) {
      // For network URLs
      backgroundImage = NetworkImage(imagePath);
    } else if (imagePath.startsWith('/') || imagePath.contains(':\\')) {
      // For absolute file paths (Android/iOS filesystem)
      backgroundImage = FileImage(File(imagePath));
    } else {
      // For asset images inside /assets
      backgroundImage = AssetImage(imagePath);
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: backgroundImage,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Color(0xFFB4FFF1),
              child: Text("Limited time!",
                  style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Up to $discount",
                    style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 16)),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Text(duration,
                style: TextStyle(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    fontSize: 14)),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB4FFF1)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailedScreen(
                      // Pass a complete service map
                      service: {
                        "name": "Car Wash",
                        "price": "500",
                        "image": "assets/images/car_wash_image.jpg", // Example path
                        "duration": "1 Hour",
                        "description": "A comprehensive car wash service."
                      },
                      // Pass the allServices list
                      allServices: [
                        {"name": "Car Wash", "price": "500", "image": "assets/images/car_wash_image.jpg", "duration": "1 Hour", "description": "A comprehensive car wash service."},
                        {"name": "Oil Change", "price": "1500", "image": "assets/images/oil_change_image.jpg", "duration": "30 Mins", "description": "Quick and efficient oil change."},
                        {"name": "Tire Rotation", "price": "800", "image": "assets/images/tire_rotation_image.jpg", "duration": "45 Mins", "description": "Ensures even tire wear."},
                      ], // example data
                    ),
                  ),
                );
              },
              child: Text("Claim", style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExpertCard(String name, String specialty, String imagePath) {
    ImageProvider backgroundImage;

    if (imagePath.startsWith('http')) {
      // Network URL
      backgroundImage = NetworkImage(imagePath);
    } else if (imagePath.startsWith('/') || imagePath.contains(':\\')) {
      // Absolute file path on device (e.g. from gallery)
      backgroundImage = FileImage(File(imagePath));
    } else {
      // Asset image bundled with the app
      backgroundImage = AssetImage(imagePath);
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: backgroundImage,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  specialty,
                  style: TextStyle(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(String imagePath, String label) {
    return Container(
      width: 105,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(imagePath, width: 90, height: 90, fit: BoxFit.cover),
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }


}
