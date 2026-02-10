import 'package:flutter/material.dart';
import '../UserScreens/AppointmentBooking.dart';

class WaxingServices extends StatefulWidget {
  @override
  _WaxingServicesState createState() => _WaxingServicesState();
}

class _WaxingServicesState extends State<WaxingServices> {
  List<Map<String, dynamic>> waxingServices = [
    {
      'name': 'Full Arms',
      'image': 'assets/FullArmWax.jpg',
      'price': 800,
      'description': 'Removes unwanted hair from both arms, leaving the skin smooth and soft.',
      'duration': '20–25 mins',
    },
    {
      'name': 'Full Legs',
      'image': 'assets/FullLegsWaxing.jpg',
      'price': 1400,
      'description': 'Complete waxing for both legs, giving a silky and clean finish.',
      'duration': '30–40 mins',
    },
    {
      'name': 'Underarms',
      'image': 'assets/UnderArmWaxing.jpg',
      'price': 400,
      'description': 'Quick and gentle waxing for underarms, ensuring freshness and smooth skin.',
      'duration': '10–15 mins',
    },
    {
      'name': 'Full Body Waxing',
      'image': 'assets/FullBodyWaxing.jpg',
      'price': 8500,
      'description': 'Comprehensive waxing for the entire body, removing hair from arms, legs, underarms, and more.',
      'duration': '90–120 mins',
    },
    {
      'name': 'Upper Lips',
      'image': 'assets/UpperLips.jpg',
      'price': 200,
      'description': 'Removes fine hair from the upper lip area for a neat and clean look.',
      'duration': '5–10 mins',
    },
    {
      'name': 'Chin',
      'image': 'assets/ChinWaxing.jpg',
      'price': 150,
      'description': 'Targets unwanted hair on the chin area, leaving skin smooth and clear.',
      'duration': '5–10 mins',
    },
    {
      'name': 'Forehead',
      'image': 'assets/ForeheadWaxing.jpg',
      'price': 350,
      'description': 'Removes excess hair from the forehead and hairline for a polished look.',
      'duration': '10–15 mins',
    },
    {
      'name': 'Full Face',
      'image': 'assets/FullFaceWaxing.jpg',
      'price': 1000,
      'description': 'Complete face waxing including upper lips, chin, forehead, and sides for a clean finish.',
      'duration': '25–30 mins',
    },

  ];

  String sortType = 'name'; // default sorting

  void sortServices(String type) {
    setState(() {
      sortType = type;
      if (type == 'name') {
        waxingServices.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (type == 'priceLowHigh') {
        waxingServices.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (type == 'priceHighLow') {
        waxingServices.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Waxing Services",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        itemCount: waxingServices.length,
        itemBuilder: (context, index) {
          final service = waxingServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                    allServices: waxingServices,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(6, 6)),
                  ],
                ),
                child: Card(
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
                        service['price'].toString(),
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
              Container(
                color: Colors.white,
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
                Text(
                  service['name'],
                  style: const TextStyle(color: Color(0xFF4F1A00), fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(service['duration'] ?? "Duration not confirmed", style: const TextStyle(fontSize: 20, color: Colors.black)),
                const SizedBox(height: 10),
                Text(
                  service['price'].toString(),
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
                                  item['price'].toString(),
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
