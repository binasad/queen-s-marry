import 'package:flutter/material.dart';
import '../UserScreens/AppointmentBooking.dart';

class MassageServices extends StatefulWidget {
  @override
  _MassageServicesState createState() => _MassageServicesState();
}

class _MassageServicesState extends State<MassageServices> {
  List<Map<String, dynamic>> massageServices = [
    {
      'name': 'Body Massage (Full)',
      'image': 'assets/FullBodyMassage.jpg',
      'price': 3500,
      'duration': '60–90 mins',
      'description': 'A complete relaxation massage using long, flowing strokes to release stress, improve circulation, and ease muscle tension from head to toe.',
    },
    {
      'name': 'Swedish Massage',
      'image': 'assets/SwedishMassage.png',
      'price': 6500,
      'duration': '60 mins',
      'description': 'A classic massage style that uses gentle to medium pressure strokes to improve blood flow, reduce stress, and promote overall relaxation.',
    },
    {
      'name': 'Deep Tissue',
      'image': 'assets/DeepTissueMassage.jpg',
      'price': 4500,
      'duration': '60 mins',
      'description': 'Targets deeper layers of muscles and connective tissue to relieve stiffness, knots, and chronic muscle pain.',
    },
    {
      'name': 'Aromatherapy (Medical Therapy)',
      'image': 'assets/AromatherapyMassage.png',
      'price': 9500,
      'duration': '45 mins',
      'description': 'A relaxing massage combined with essential oils to calm the mind, reduce stress, and support overall well-being.',
    },
    {
      'name': 'Therapeutic Massage (Fat Dissolving)',
      'image': 'assets/TherapeuticMassage.jpg',
      'price': 12500,
      'duration': '45–60 mins',
      'description': 'A specialized massage designed to stimulate circulation and target fat deposits, helping in body shaping and detoxification.',
    },
    {
      'name': 'Scalp Massage',
      'image': 'assets/ScalpMassage.png',
      'price': 1000,
      'duration': '20–30 mins',
      'description': 'Gentle massage focusing on the scalp and pressure points to relieve headaches, improve blood flow, and promote hair growth.',
    },
    {
      'name': 'Neck & Shoulder Relief',
      'image': 'assets/NeckAndShoulderRelief.jpg',
      'price': 1500,
      'duration': '30–45 mins',
      'description': 'Focused massage on the neck and shoulder area to relieve stiffness, tension, and pain caused by stress or long hours at work.',
    },
    {
      'name': 'Relaxing Foot Massage',
      'image': 'assets/RelaxingFoot.png',
      'price': 1000,
      'duration': '30–45 mins',
      'description': 'A soothing foot massage with pressure point therapy to relieve fatigue, improve circulation, and restore body balance.',
    },
    {
      'name': 'Stress Relief Session',
      'image': 'assets/StressRelief.jpg',
      'price': 2500,
      'duration': '20–40 mins',
      'description': 'A quick, refreshing session targeting stress points in the body to calm the mind, relax muscles, and boost energy instantly.',
    },

  ];

  String selectedSort = 'Name'; // Default sort type

  @override
  void initState() {
    super.initState();
    sortServices('Name'); // sort initially
  }

  int _extractPrice(String priceString) {
    // Extract numeric value from 'PKR 1,200'
    return int.parse(priceString.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  String sortType = 'name'; // default sorting

  void sortServices(String type) {
    setState(() {
      sortType = type;
      if (type == 'name') {
        massageServices.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (type == 'priceLowHigh') {
        massageServices.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (type == 'priceHighLow') {
        massageServices.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Massage Services",
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
        itemCount: massageServices.length,
        itemBuilder: (context, index) {
          final service = massageServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                    allServices: massageServices,
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
                      Color(0xFFFF6CBF), // light pink
                      Color(0xFFFFC371), // soft peach
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
