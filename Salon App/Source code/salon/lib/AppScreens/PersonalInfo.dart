import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPersonalInfo extends StatefulWidget {
  const UserPersonalInfo({Key? key}) : super(key: key);

  @override
  State<UserPersonalInfo> createState() => _UserPersonalInfoState();
}

class _UserPersonalInfoState extends State<UserPersonalInfo> {
  String? role;
  String name = "", email = "", switchUser = "",profile = "";
  // Editable state variables
  String userName = "";
  String userEmail = "";
  DateTime? selectedDate;
  String phone = "";
  String address = "Street 111A, I8/4";
  String gender = "Male";
  File? profileImage;
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection("users").doc(user.uid).get();
        setState(() {
          userEmail = user.email ?? "";
          if (doc.exists) {
            userName = doc.data()?["name"] ?? user.displayName ?? "No Name";
            phone = doc.data()?["phone"] ?? "";
            address = doc.data()?["address"] ?? address;
            gender = doc.data()?["gender"] ?? gender;
          } else {
            // If no Firestore doc exists, use Auth displayName
            userName = user.displayName ?? "No Name";
          }
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          userEmail = user.email ?? "";
          userName = user.displayName ?? "No Name";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userName = "Guest";
        userEmail = "";
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Save to Firestore
      await _firestore.collection("users").doc(user.uid).set({
        "name": newName,
        "email": user.email,
        "phone": phone,
        "address": address,
        "gender": gender,
      }, SetOptions(merge: true));

      // Also update FirebaseAuth displayName
      await user.updateDisplayName(newName);
      await user.reload();

      setState(() {
        userName = newName;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.blueGrey,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (datePicked != null && datePicked != selectedDate) {
      setState(() {
        selectedDate = datePicked;
      });
    }
  }

  Future<void> _editField(String title, String currentValue, Function(String) onSave) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editGender() async {
    String tempGender = gender;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Select Gender"),
        content: StatefulBuilder(
          builder: (context, setInnerState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text("Male"),
                value: "Male",
                groupValue: tempGender,
                onChanged: (val) {
                  setInnerState(() => tempGender = val!);
                },
              ),
              RadioListTile<String>(
                title: const Text("Female"),
                value: "Female",
                groupValue: tempGender,
                onChanged: (val) {
                  setInnerState(() => tempGender = val!);
                },
              ),
              RadioListTile<String>(
                title: const Text("Other"),
                value: "Other",
                groupValue: tempGender,
                onChanged: (val) {
                  setInnerState(() => tempGender = val!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => gender = tempGender);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.photo),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() => profileImage = File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.camera),
              title: const Text("Take a Photo"),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() => profileImage = File(pickedFile.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Personal Info"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green[200],
                  // child: Text(
                  //   userName.isNotEmpty ? userName[0].toUpperCase() : '',
                  //   style: TextStyle(fontSize: 28, color: Colors.grey.shade200),
                  // ),
                  child: ClipOval(
                    child: Image.network(profile,
                      fit: BoxFit.cover,
                      width: 90, // diameter = radius * 2
                      height: 90,
                      // جب image لوڈ ہو رہی ہو
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      // جب error آئے
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        return Image.asset("assets/profile.jpg",
                          fit: BoxFit.cover,
                          width: 90, // diameter = radius * 2
                          height: 90,
                        );
                      },
                    ),
                    // Image.asset(
                    //   "assets/profile.jpg",
                    //   fit: BoxFit.cover,
                    //   width: 90, // diameter = radius * 2
                    //   height: 90,
                    // ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(CupertinoIcons.person),
            title: Text(userName),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editField("Username", userName, (val) {
              _updateUserName(val); // <-- save to Firebase
            }),
          ),
          ListTile(
            leading: Icon(CupertinoIcons.mail),
            title: Text(userEmail),
          ),
          ListTile(
            leading: Icon(CupertinoIcons.calendar_today),
            title: Text(
              selectedDate == null
                  ? "Select Date of Birth"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            ),
            trailing: Icon(CupertinoIcons.calendar_badge_minus),
            onTap: () => _pickDate(context),
          ),
          ListTile(
            leading: Icon(CupertinoIcons.phone),
            title: Text(phone.isEmpty ? "Add Phone" : phone),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editField("Phone", phone, (val) {
              setState(() => phone = val);
            }),
          ),
          ListTile(
            leading: Icon(CupertinoIcons.home),
            title: Text(address),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editField("Address", address, (val) {
              setState(() => address = val);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text("Gender: $gender"),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editGender,
          ),
        ],
      ),
    );
  }
}
