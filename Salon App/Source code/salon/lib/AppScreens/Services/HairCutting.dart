import 'package:flutter/material.dart';

import '../UserScreens/AppointmentBooking.dart';

class HairCutScreen extends StatefulWidget {
  @override
  _HairCutScreenState createState() => _HairCutScreenState();
}

class _HairCutScreenState extends State<HairCutScreen> {
  List<Map<String, dynamic>> hairCutServices = [
    {
      'name': 'Wispy Haircut',
      'image': 'assets/WispyHaircut.png',
      'price': 2500,
      'description': 'A soft, layered cut with feathered ends that adds lightness, movement, and a feminine frame to your face.',
      'duration': '40 mins',
    },
    {
      'name': 'Long Layers Haircut',
      'image': 'assets/LongLayerHaircut.png',
      'price': 1500,
      'description': 'Classic long layers that add bounce, volume, and natural flow while keeping length intact.',
      'duration': '45 mins',
    },
    {
      'name': 'Bob Haircut',
      'image': 'assets/BobHaircut.png',
      'price': 2000,
      'description': 'A sleek, stylish short haircut that can be worn straight or textured for a modern look.',
      'duration': '35 mins',
    },
    {
      'name': 'Pixie Haircut',
      'image': 'assets/PixieHaircut.png',
      'price': 3000,
      'description': 'A chic, low-maintenance short cut that enhances your features with bold style.',
      'duration': '40 mins',
    },
    {
      'name': 'Bangs Haircut',
      'image': 'assets/BangsHaircut.png',
      'price': 2500,
      'description': 'Fresh, stylish bangs tailored to your face shape for a youthful and trendy look.',
      'duration': '25 mins',
    },
    {
      'name': 'Butterfly Haircut',
      'image': 'assets/ButterflyHaircut.png',
      'price': 2000,
      'description': 'A layered haircut with face-framing waves that creates volume and a soft, fluttery effect.',
      'duration': '50 mins',
    },
    {
      'name': 'Wolf Haircut',
      'image': 'assets/WolfHaircut.png',
      'price': 1500,
      'description': 'A bold, edgy cut combining shaggy layers with a mullet-inspired shape for volume and texture.',
      'duration': '50 mins',
    },
    {
      'name': 'Blunt Haircut',
      'image': 'assets/BluntHaircut.jpg',
      'price': 1500,
      'description': 'A sharp, even-length haircut that gives a bold, sleek, and modern appearance.',
      'duration': '30 mins',
    },
    {
      'name': 'Baby Bangs',
      'image': 'assets/BabyBangsHaircut.jpg',
      'price': 1500,
      'description': 'Short, edgy bangs cut above the eyebrows for a bold and stylish statement look.',
      'duration': '20 mins',
    },
    {
      'name': 'Baby Cutting',
      'image': 'assets/BabyCutting.jpg',
      'price': 1500,
      'description': 'Gentle, safe haircutting service for kids, keeping them comfortable and stylish.',
      'duration': '25 mins',
    },
    {
      'name': 'Feather Haircut',
      'image': 'assets/FeatherCutting.png',
      'price': 2500,
      'description': 'A soft, feathered layering technique that adds shape, volume, and lightness to your hair.',
      'duration': '45 mins',
    },
    {
      'name': 'Wash/ Blow dry',
      'image': 'assets/BlowDryAndStraigntening.jpg',
      'price': 1500,
      'description': 'Professional wash followed by a smooth blow-dry for silky, bouncy, and styled hair.',
      'duration': '35 mins',
    },
    {
      'name': 'Ironing/Straightening',
      'image': 'assets/HairIroningAndStraightening.jpg',
      'price': 1000,
      'description': 'Temporary straightening with a flat iron to achieve sleek, shiny, and smooth hair.',
      'duration': '45 mins',
    },
    {
      'name': 'Curls/ Waves',
      'image': 'assets/CurlsAndWaves.jpg',
      'price': 2000,
      'description': 'Heat-styled curls or waves for a glamorous, voluminous, and party-ready look.',
      'duration': '45 mins',
    },

  ];

  @override
  void initState() {
    super.initState();
    // Convert price to int for sorting
    for (var service in hairCutServices) {
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
  //       hairCutServices.sort((a, b) => a['name'].compareTo(b['name']));
  //     } else if (type == 'priceLowHigh') {
  //       hairCutServices.sort((a, b) => a['price'].compareTo(b['price']));
  //     } else if (type == 'priceHighLow') {
  //       hairCutServices.sort((a, b) => b['price'].compareTo(a['price']));
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
        itemCount: hairCutServices.length,
        itemBuilder: (context, index) {
          final service = hairCutServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                    allServices: hairCutServices,
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
