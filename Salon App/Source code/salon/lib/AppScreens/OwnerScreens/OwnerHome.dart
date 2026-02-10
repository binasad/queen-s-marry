import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:salon/AppScreens/PersonalInfo.dart';
import '../../Manager/ExpertManager.dart';
import '../../Manager/OfferManager.dart';
import '../Settings.dart';
import '../googleMap.dart';
import 'OwnerDrawer.dart';
class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  String location = "I8 Markaz, ISB";
  String searchQuery = "";

  // Helper to filter offers based on search
  List<Map<String, String>> get filteredOffers {
    if (searchQuery.isEmpty) return OfferManager.offers;
    return OfferManager.offers
        .where((offer) =>
    offer["title"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
        offer["discount"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (offer["duration"] ?? "")
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  // Helper to filter experts based on search
  List<Map<String, String>> get filteredExperts {
    if (searchQuery.isEmpty) return ExpertManager.experts;
    return ExpertManager.experts
        .where((expert) =>
    expert["name"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
        expert["specialty"]!
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddOfferDialog() {
    String title = '';
    String discount = '';
    String duration = '';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setInnerState(() {
                  selectedImage = File(pickedFile.path);
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Add New Offer"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: "Offer Title"),
                      onChanged: (val) => title = val,
                    ),
                    TextField(
                      decoration:
                      InputDecoration(labelText: "Discount (e.g. 30%)"),
                      onChanged: (val) => discount = val,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Duration"),
                      onChanged: (val) => duration = val,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(CupertinoIcons.photo),
                      label: Text("Pick Image"),
                    ),
                    if (selectedImage != null)
                      Image.file(selectedImage!, height: 100)
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Add"),
                  onPressed: () {
                    if (title.isNotEmpty &&
                        discount.isNotEmpty &&
                        duration.isNotEmpty &&
                        selectedImage != null) {
                      setState(() {
                        OfferManager.addOffer(
                          title: title,
                          discount: discount,
                          duration: duration,
                          image: selectedImage!.path,
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExpertDialog() {
    String name = '';
    String specialty = '';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setInnerState(() {
                  selectedImage = File(pickedFile.path);
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Add New Expert"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: "Expert Name"),
                      onChanged: (val) => name = val,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Specialty"),
                      onChanged: (val) => specialty = val,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(CupertinoIcons.photo),
                      label: Text("Pick Image"),
                    ),
                    if (selectedImage != null)
                      Image.file(selectedImage!, height: 100)
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Add"),
                  onPressed: () {
                    if (name.isNotEmpty &&
                        specialty.isNotEmpty &&
                        selectedImage != null) {
                      setState(() {
                        ExpertManager.addExpert(
                          name: name,
                          specialty: specialty,
                          image: selectedImage!.path,
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
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
    return name.isNotEmpty ?Scaffold(
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
                    Text("Hello, ", style: TextStyle(color: Colors.black)),
                    Text("${name}",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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
                // Image.asset(
                //   "assets/profile.jpg",
                //   fit: BoxFit.cover,
                //   width: 90, // diameter = radius * 2
                //   height: 90,
                // ),
              ),
            )

          ],
        ),
      ),
      drawer: OwnerDrawer(),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationRow(context),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),

              // Offers Section
              _buildSectionHeader("#SpecialForYou", onSeeAll: () {}),
              const SizedBox(height: 12),
              Container(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredOffers.length + 2, // +1 for dummy, +1 for add card
                  separatorBuilder: (_, __) => SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    if (index < filteredOffers.length) {
                      // Normal offer cards
                      final offer = filteredOffers[index];
                      return _buildOfferCard(
                        offer["title"]!,
                        offer["discount"]!,
                        offer["image"]!,
                        duration: offer["duration"] ?? "Limited",
                      );
                    } else if (index == filteredOffers.length) {
                      // Insert dummy card here
                      return _buildOfferCard(
                        "Coming Soon",
                        "??%",
                        "assets/bgbg.png", // or any dummy image
                        duration: "TBD",
                      );
                    } else {
                      // Last card → Add offer card
                      return _buildAddOfferCard();
                    }
                  },
                ),
              ),


              SizedBox(height: 24),
              _buildSectionHeader("#OurExperts", onSeeAll: () {}),
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
                        "Coming Soon",
                        "Specialty TBD",
                        "assets/profile.jpg", // must be in pubspec.yaml
                      );
                    } else {
                      // Add Expert card
                      return _buildAddExpertCard();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ): Center( child: CircularProgressIndicator(),);
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search Salon, Specialist...",
          prefixIcon: Icon(CupertinoIcons.search, color: Colors.pink),
          suffixIcon: const Icon(Icons.filter_list, color: Colors.pink),
          filled: true,
          fillColor: const Color(0xFFB4FFF1),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- Cards, Add buttons, Section headers stay the same ---
  Widget _buildOfferCard(String title, String discount, String imagePath,
      {String duration = "Limited"}) {
    return _buildCard(title, discount, imagePath, duration);
  }

  Widget _buildExpertCard(String name, String specialty, String imagePath) {
    ImageProvider backgroundImage;

    if (imagePath.startsWith('http')) {
      // Network image
      backgroundImage = NetworkImage(imagePath);
    } else if (imagePath.startsWith('/') || imagePath.contains(':\\')) {
      // Local file path on device
      backgroundImage = FileImage(File(imagePath));
    } else {
      // Flutter asset image
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
                Text(name,
                    style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(specialty,
                    style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCard(String title, String subtitle, String imagePath, [String duration = ""]) {
    ImageProvider backgroundImage;

    if (imagePath.startsWith('http')) {
      // For network URLs
      backgroundImage = NetworkImage(imagePath);
    } else if (imagePath.startsWith('/') || imagePath.contains(':\\')) {
      // For absolute file paths on device
      backgroundImage = FileImage(File(imagePath));
    } else {
      // For Flutter assets
      backgroundImage = AssetImage(imagePath);
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: backgroundImage, fit: BoxFit.cover),
      ),
      child: Stack(children: [
        Positioned(
            top: 12,
            left: 12,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Color(0xFFB4FFF1),
                child: Text(duration.isNotEmpty ? "Limited time!" : "Expert",
                    style: TextStyle(color: Colors.black, fontSize: 12)))),
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
                  Text(subtitle,
                      style: TextStyle(
                          backgroundColor: Colors.white,
                          color: Colors.black,
                          fontSize: 16)),
                ])),
        if (duration.isNotEmpty)
          Positioned(
              bottom: 12,
              left: 12,
              child: Text(duration,
                  style: TextStyle(
                      backgroundColor: Colors.white,
                      color: Colors.black,
                      fontSize: 14))),
      ]),
    );
  }


  Widget _buildAddOfferCard() {
    return _buildAddCard("Add New Offer", _showAddOfferDialog);
  }

  Widget _buildAddExpertCard() {
    return _buildAddCard("Add New Expert", _showAddExpertDialog);
  }

  Widget _buildAddCard(String label, VoidCallback onTap) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_card, size: 48, color: Colors.pink),
                SizedBox(height: 12),
                Text(label,
                    style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(children: [
        Lottie.asset('assets/LocationPin.json', width: 40, height: 40),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => GoogleMapScreen()));
          },
          child: Text(location,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black)),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.pink[50],
          child: Lottie.asset('assets/Bellring.json', width: 40, height: 40),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text("See All",
                style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}


