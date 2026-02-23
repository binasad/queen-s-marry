import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'googleMap.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color brandPink = Color(0xFFFF0068);
  static const Color accentPeach = Color(0xFFFFC371);
  static const Color softPink = Color(0xFFFF6CBF);
  static const Color deepCharcoal = Color(0xFF1A1A2E);
  static const Color warmWhite = Color(0xFFFAFAFC);

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) throw 'Could not launch $uri';
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeFull('subject=Booking Inquiry&body=Hi Queen\'s Marry Team,'),
    );
    if (!await launchUrl(uri)) throw 'Could not launch $uri';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: warmWhite),
                  // Logo with premium ring
                  Center(
                    child: Hero(
                      tag: 'salon_logo',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 0,
                              offset: const Offset(0, -2),
                              spreadRadius: 0,
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage("assets/logo.png"),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 56),
              child: Column(
                children: [
                  // Brand name with refined typography
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [deepCharcoal, Color(0xFF2D2D44)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      "Queen's Marry",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Description
                  Text(
                    "At Queen's Marry, we believe every individual deserves a moment of luxury. Our team of skilled professionals specializes in crafting looks that celebrate your unique personality.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.7,
                      color: deepCharcoal.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Action Cards
                  _buildActionCard(
                    context,
                    icon: CupertinoIcons.phone_fill,
                    title: "Call Us",
                    subtitle: "+92-308-5494369",
                    onTap: () => _launchPhone("+923085494369"),
                  ),
                  const SizedBox(height: 14),
                  _buildActionCard(
                    context,
                    icon: CupertinoIcons.mail_solid,
                    title: "Email Support",
                    subtitle: "info@queensmarry.com",
                    onTap: () => _launchEmail("info@queensmarry.com"),
                  ),
                  const SizedBox(height: 14),
                  _buildActionCard(
                    context,
                    icon: CupertinoIcons.location_solid,
                    title: "Our Studio",
                    subtitle: "I8 Markaz, Islamabad, Pakistan",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoogleMapScreen())),
                  ),

                  const SizedBox(height: 56),
                  Text(
                    "App Version 1.0.4",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: brandPink.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: brandPink.withOpacity(0.08),
              highlightColor: brandPink.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            brandPink.withOpacity(0.12),
                            softPink.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: brandPink.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: brandPink, size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: deepCharcoal,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

