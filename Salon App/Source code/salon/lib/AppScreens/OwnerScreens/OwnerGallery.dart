import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../UserScreens/UserGallery.dart';

class AdminGalleryScreen extends StatefulWidget {
  static List<File> galleryImages = []; // Shared with user screen

  @override
  _AdminGalleryScreenState createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        AdminGalleryScreen.galleryImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      AdminGalleryScreen.galleryImages.removeAt(index);
    });
  }

  void _goToUserScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserGalleryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Admin Gallery"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.person_fill,
              color: Colors.black,
              size: 35,
            ),
            onPressed: _goToUserScreen,
          )
        ],
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
      body: Stack(
        children: [
          Opacity(
            opacity: 0.99,
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 5),
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight + 20),
              child: AdminGalleryScreen.galleryImages.isEmpty
                  ? const Center(
                child: Text(
                  "No images yet.\nAdd from camera or gallery!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AdminGalleryScreen.galleryImages.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            AdminGalleryScreen.galleryImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.delete,
                                  color: Colors.white, size: 18),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // 🔹 FAB ko custom location par rakhna
          Positioned(
            bottom: 60, // jitna upar chahiye
            right: 10, // jitna left/right chahiye
            child: _buildFab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -120),
      icon: Material(
        elevation: 9,
        shape: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6CBF), // pink
                Color(0xFFFFC371), // peach
              ],
            ),
          ),
          child: const Icon(Icons.add_a_photo_outlined,
              color: Colors.black, size: 28),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(CupertinoIcons.photo, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Pick from Gallery"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(CupertinoIcons.camera, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Capture with Camera"),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'gallery') {
          _pickImage(ImageSource.gallery);
        } else if (value == 'camera') {
          _pickImage(ImageSource.camera);
        }
      },
    );
  }
}
