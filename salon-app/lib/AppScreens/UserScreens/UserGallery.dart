import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../OwnerScreens/OwnerGallery.dart';

class UserGalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final images = AdminGalleryScreen.galleryImages; // shared list

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Gallery",
          style: TextStyle(fontWeight: FontWeight.bold),),
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
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.99,
            child:
            Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9), // control blur strength
            child: Container(
              color: Colors.white.withOpacity(0.1), // transparent layer to apply blur
            ),
          ),
          Container(
          child: images.isEmpty
              ? const Center(
            child: Text(
              "No images available",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Optional: small index indicator at bottom
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ]
      ),
    );
  }
}
