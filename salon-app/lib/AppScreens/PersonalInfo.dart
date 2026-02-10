import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as provider_package;
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../utils/error_handler.dart';
import '../utils/guest_guard.dart';

class UserPersonalInfo extends StatefulWidget {
  const UserPersonalInfo({Key? key}) : super(key: key);

  @override
  State<UserPersonalInfo> createState() => _UserPersonalInfoState();
}

class _UserPersonalInfoState extends State<UserPersonalInfo> {
  String? role;
  String name = "", email = "", switchUser = "", profile = "";
  // Editable state variables
  String userName = "";
  String userEmail = "";
  DateTime? selectedDate;
  String phone = "";
  String address = "";
  String gender = "Male";
  File? profileImage;
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userData = await UserService().getProfile();
      final user = userData['user'];

      setState(() {
        userName = user['name'] ?? "No Name";
        userEmail = user['email'] ?? "";
        phone = user['phone'] ?? "";
        address = user['address'] ?? "";
        gender = user['gender'] ?? "Male";
        profile = user['profile_image_url'] ?? "";
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ErrorHandler.show(context, e);
    }
  }

  Future<void> _updateUserInfo() async {
    // Check if user is a guest - guests cannot update profile
    final canProceed = await GuestGuard.canPerformAction(
      context,
      actionDescription: 'update your profile',
    );
    if (!canProceed) return;

    try {
      setState(() => isLoading = true);

      await UserService().updateProfile(
        name: userName,
        phone: phone,
        address: address,
        gender: gender,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ErrorHandler.show(context, e);
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

  Future<void> _editField(
    String title,
    String currentValue,
    Function(String) onSave,
  ) async {
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
              _updateUserInfo();
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
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
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
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                );
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
                          child: Image.network(
                            profile,
                            fit: BoxFit.cover,
                            width: 90, // diameter = radius * 2
                            height: 90,
                            // جب image لوڈ ہو رہی ہو
                            loadingBuilder:
                                (
                                  BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                (loadingProgress
                                                        .expectedTotalBytes ??
                                                    1)
                                          : null,
                                    ),
                                  );
                                },
                            // جب error آئے
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return Image.asset(
                                    "assets/profile.jpg",
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
                    setState(() => userName = val);
                    _updateUserInfo();
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
                    _updateUserInfo();
                  }),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.home),
                  title: Text(address),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editField("Address", address, (val) {
                    setState(() => address = val);
                    _updateUserInfo();
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
