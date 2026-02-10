import 'package:flutter/material.dart';

import '../UserScreens/AppointmentBooking.dart';

class HairTreatmentScreen extends StatefulWidget {
  @override
  _HairTreatmentScreenState createState() => _HairTreatmentScreenState();
}

class _HairTreatmentScreenState extends State<HairTreatmentScreen> {
  List<Map<String, dynamic>> hairTreatmentServices = [
    {
      'name': 'Hair Spa',
      'image': 'assets/HairSpa.png',
      'price': 2500,
      'description': 'A relaxing spa therapy that deeply nourishes, repairs, and revitalizes dry or damaged hair.',
      'duration': '60 mins',
    },
    {
      'name': 'Deep Conditioning + Blowdry',
      'image': 'assets/DeepConditioning.png',
      'price': 1500,
      'description': 'An intensive conditioning treatment followed by a professional blow-dry for smooth, silky, and frizz-free hair.',
      'duration': '45 mins',
    },
    {
      'name': 'Keratin Treatment',
      'image': 'assets/KeratinTreatment.png',
      'price': 12000,
      'description': 'A smoothing therapy that reduces frizz, strengthens hair, and adds lasting shine with keratin infusion.',
      'duration': '2–3 hrs',
    },
    {
      'name': 'Protein Treatment',
      'image': 'assets/ProteinTreatment.png',
      'price': 18000,
      'description': 'Rebuilds and strengthens weak, brittle, or chemically treated hair by restoring lost proteins.',
      'duration': '90 mins',
    },
    {
      'name': 'Extenso Treatment (6 Sessions)',
      'image': 'assets/ExtensoTreatment.png',
      'price': 45000,
      'description': 'A professional hair straightening system that gives smooth, sleek, and manageable hair across multiple sessions.',
      'duration': '2–3 hrs per session',
    },
    {
      'name': 'Herbal Treatment',
      'image': 'assets/HerbalTreatment.jpg',
      'price': 4000,
      'description': 'An herbal therapy using natural extracts to reduce dandruff, strengthen roots, and improve scalp health.',
      'duration': '60 mins',
    },
    {
      'name': 'Smoothening / Rebounding',
      'image': 'assets/Smoothening.png',
      'price': 3500,
      'description': 'A semi-permanent straightening treatment that smooths frizz and makes hair silky, shiny, and manageable.',
      'duration': '3–4 hrs',
    },
    {
      'name': 'Scalp Treatment',
      'image': 'assets/ScalpTreatment.png',
      'price': 6500,
      'description': 'Targets scalp concerns such as dandruff, dryness, or excess oil while boosting circulation and promoting healthy growth.',
      'duration': '50 mins',
    },

  ];

  @override
  void initState() {
    super.initState();
    // Convert price to int for sorting
    for (var service in hairTreatmentServices) {
      final priceStr = service['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      service['priceValue'] = int.parse(priceStr);
    }
  }

  // String sortType = 'name'; // default sorting
  //
  // void sortServices(String type) {
  //   setState(() {
  //     sortType = type;
  //     if (type == 'name') {
  //       hairTreatmentServices.sort((a, b) => a['name'].compareTo(b['name']));
  //     } else if (type == 'priceLowHigh') {
  //       hairTreatmentServices.sort((a, b) => a['price'].compareTo(b['price']));
  //     } else if (type == 'priceHighLow') {
  //       hairTreatmentServices.sort((a, b) => b['price'].compareTo(a['price']));
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     "Hair Services",
      //     style: TextStyle(
      //       fontSize: 24,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   backgroundColor: Colors.white,
      //   actions: [
      //     PopupMenuButton<String>(
      //       icon: const Icon(Icons.sort, color: Colors.black),
      //       color: Color(0xFFFFE1F0),
      //       onSelected: sortServices,
      //       itemBuilder: (context) => [
      //         PopupMenuItem(
      //           value: 'name',
      //           child: Row(
      //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //             children: [
      //               const Text('Sort by Name'),
      //               if (sortType == 'name') const Icon(Icons.check, size: 18),
      //             ],
      //           ),
      //         ),
      //         PopupMenuItem(
      //           value: 'priceLowHigh',
      //           child: Row(
      //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //             children: [
      //               const Text('Price: Low to High'),
      //               if (sortType == 'priceLowHigh') const Icon(Icons.check, size: 18),
      //             ],
      //           ),
      //         ),
      //         PopupMenuItem(
      //           value: 'priceHighLow',
      //           child: Row(
      //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //             children: [
      //               const Text('Price: High to Low'),
      //               if (sortType == 'priceHighLow') const Icon(Icons.check, size: 18),
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: hairTreatmentServices.length,
        itemBuilder: (context, index) {
          final service = hairTreatmentServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                    allServices: hairTreatmentServices,
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
                                Text("${service['price']} PKR",
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
