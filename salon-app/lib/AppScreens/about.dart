import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'googleMap.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  // Help for launching
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeFull('subject=Booking Inquiry&body=Hi Merry Queen,'),
    );
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  void _openGoogleMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoogleMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("About Us"),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6CBF), // pink
                Color(0xFFFFC371), // peach
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6CBF), // pink
              Color(0xFFFFC371), // peach
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
          // borderRadius: BorderRadius.only(
          //   topLeft: Radius.circular(60),
          //   topRight: Radius.circular(60),
          // ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Salon Logo
                CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/logo.png"), // replace with your logo
                  // backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 20),

                // Salon Name
                const Text(
                  "Merry Queen",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 10),

                // Tagline
                const Text(
                  "Where beauty meets perfection",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  "At Merry Queen, we believe every client deserves to look "
                      "and feel their best. Our team of skilled professionals offers a wide "
                      "range of services, from hair styling and makeup to skincare and spa "
                      "treatments — all tailored to your unique style and personality.",
                  style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Contact Info
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(CupertinoIcons.phone, color: Colors.purple),
                          title: const Text("+92-308-5494369"),
                          onTap: () => _launchPhone("+923085494369"),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(CupertinoIcons.mail, color: Colors.purple),
                          title: const Text("info@merryqueen.com"),
                          onTap: () => _launchEmail("info@merryqueen.com"),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(CupertinoIcons.map_pin_ellipse, color: Colors.purple),
                          title: const Text("I8 Markaz, Islamabad, Pakistan"),
                          onTap: () => _openGoogleMapScreen(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Version Info
                const Text(
                  "App Version 1.0.0",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
