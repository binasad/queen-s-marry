import 'package:flutter/material.dart';
import '../UserScreens/AppointmentBooking.dart';

class MakeUpServices extends StatefulWidget {
  @override
  _MakeUpServicesState createState() => _MakeUpServicesState();
}

class _MakeUpServicesState extends State<MakeUpServices> {
  List<Map<String, dynamic>> makeUpServices = [
    {
      'name': 'Party Makeup (Pakistani)',
      'image': 'assets/PartyMakeup.jpg',
      'price': 7000,
      'description': 'A traditional Pakistani party look with soft glam, defined eyes, and flawless base for birthdays, dinners, or casual events.',
      'duration': '60 mins',
    },
    {
      'name': 'Turkish Party Look',
      'image': 'assets/LightPartyLook.jpg',
      'price': 5000,
      'description': 'A natural Turkish-inspired soft glam with subtle tones, glowing skin, and light eye makeup for a fresh look.',
      'duration': '45 mins',
    },
    {
      'name': 'Smokey & Glam Look',
      'image': 'assets/GlamLook.png',
      'price': 15000,
      'description': 'Dramatic smokey eyes paired with bold lips and glowing skin — perfect for night parties, receptions, and red-carpet glam.',
      'duration': '75 mins',
    },
    {
      'name': 'Engagement Look',
      'image': 'assets/EngagementLook.jpg',
      'price': 15000,
      'description': 'A semi-glam, graceful makeup style with soft shimmer and radiant base, tailored for engagement ceremonies.',
      'duration': '90 mins',
    },
    {
      'name': 'Nikkah Signature Makeup',
      'image': 'assets/NikkahLook.jpg',
      'price': 20000,
      'description': 'A soft yet elegant bridal look with pastel tones, natural glam, and a flawless long-lasting base for Nikkah ceremonies.',
      'duration': '2 hrs',
    },
    {
      'name': 'Barat Signature Makeup',
      'image': 'assets/BaratLook.jpg',
      'price': 35000,
      'description': 'A bold, vibrant, and full-coverage bridal look for Barat day, complete with detailed eye makeup and traditional glam.',
      'duration': '3 hrs',
    },
    {
      'name': 'Walima Signature Makeup',
      'image': 'assets/WalimaLook.jpg',
      'price': 30000,
      'description': 'A soft glam Walima look with elegant tones, glowing skin, and graceful styling for a dreamy bridal appearance.',
      'duration': '2 hrs',
    },
    {
      'name': 'Full Bridal Package',
      'image': 'assets/BridalPackage.jpg',
      'price': 45000,
      'description': 'Complete bridal package including Nikkah, Barat, and Walima looks — ensuring flawless glam for all wedding events.',
      'duration': 'Varies (2–3 hrs per event)',
    },
    {
      'name': 'Sangeet Makeup',
      'image': 'assets/Sangeet.png',
      'price': 10000,
      'description': 'A colorful, festive look with shimmery eyes and radiant glow, designed to complement vibrant sangeet celebrations.',
      'duration': '90 mins',
    },

  ];

  @override
  void initState() {
    super.initState();
    // Extract numeric price for reliable sorting
    for (var service in makeUpServices) {
      final priceStr =
      service['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      service['priceValue'] = int.tryParse(priceStr) ?? 0;
    }
  }

  String sortType = 'name'; // default sorting

  void sortServices(String type) {
    setState(() {
      sortType = type;
      if (type == 'name') {
        makeUpServices.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (type == 'priceLowHigh') {
        makeUpServices.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (type == 'priceHighLow') {
        makeUpServices.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MakeUp Services",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            color: Color(0xFFFFE1F0),
            onSelected: sortServices,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sort by Name'),
                    if (sortType == 'name') const Icon(Icons.check, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priceLowHigh',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Price: Low to High'),
                    if (sortType == 'priceLowHigh') const Icon(Icons.check, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priceHighLow',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Price: High to Low'),
                    if (sortType == 'priceHighLow') const Icon(Icons.check, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: makeUpServices.length,
        itemBuilder: (context, index) {
          final service = makeUpServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                    allServices: makeUpServices,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF6CBF),
                      Color(0xFFFFC371),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(6, 6),
                    ),
                  ],
                ),
                child: Card(
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        service['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      service['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        "PKR ${service['priceValue']}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


// Example detail screen (you can customize)
class ServiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> service;
  final List<Map<String, dynamic>> allServices;

  const ServiceDetailScreen({Key? key, required this.service, required this.allServices})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final relatedServices = allServices
        .where((s) => s['name'] != service['name'])
        .toList();


    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(color: Colors.white,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(service['image']),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(90),
                      bottomRight: Radius.circular(90),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF6D2E2E),
                      Color(0xFFB26E6E),
                      Color(0xFFD79191),
                      Color(0xFFE4B1B1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: Text(
                    service['name'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // the color here is required but will be overridden by shader
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(service['duration'] ?? "Duration not confirmed", style: const TextStyle(fontSize: 20, color: Colors.black)),
                const SizedBox(height: 10),
                Text(
                  "${service['price']} PKR",
                  style: const TextStyle(fontSize: 22, color: Colors.pink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40),
                  child: Column(
                    children: [
                      const Text("Your Overall Rating of the Product"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          return const Icon(Icons.star, color: Colors.amber, size: 40);
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(service['description'] ?? "No description provided.", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentBookingScreen(service: service),
                      ),
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(minHeight: 50),
                      child: const Text(
                        "Book Appointment",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20,),
                const Text("You may also like", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: relatedServices.length,
                    itemBuilder: (context, index) {
                      final item = relatedServices[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(service: item, allServices: allServices),
                            ),
                          );
                        },
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(3, 3)),
                            ],
                          ),
                          child: Card(
                            color: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(item['image'], width: 100, height: 80, fit: BoxFit.cover),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${service['price']} PKR",
                                  style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
