import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareWithFriends extends StatelessWidget {
  const ShareWithFriends({super.key});

  static const Color brandPink = Color(0xFFFF0068);
  final String inviteCode = "SALON123";

  void _shareInvite(BuildContext context) {
    final String message =
        "✨ Join this amazing salon app and get exclusive offers!\n\nUse my invite code: $inviteCode\n\nDownload here: https://play.google.com/store/apps/details?id=com.example.salon";
    Share.share(message, subject: "Salon App Invite");
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Invite code copied to clipboard!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: brandPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Invite Friends", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Decorative background element
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: brandPink.withOpacity(0.05)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Premium Illustration Card
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      "assets/ShareWithFriends.jpg",
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                const Text(
                  "Share the Love!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "Invite your friends to the salon. They get a discount, and you earn loyalty rewards!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                ),
                
                const SizedBox(height: 40),
                
                // Invite Code Box with Copy Feature
                const Text(
                  "YOUR REFERRAL CODE",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: brandPink.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: brandPink.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          inviteCode,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: brandPink, letterSpacing: 2),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.copy_rounded, color: brandPink, size: 20),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Primary Action Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareInvite(context),
                    icon: const Icon(Icons.ios_share, color: Colors.white),
                    label: const Text(
                      "Share with Friends",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: brandPink.withOpacity(0.4),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}