import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'CoursesScreen.dart';
import '../../../services/course_service.dart';

class ApplyFormScreen extends StatefulWidget {
  final String course;
  final String? courseId;
  final String? offerId;

  const ApplyFormScreen({
    super.key,
    required this.course,
    this.courseId,
    this.offerId,
  });

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController numberCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.courseId != null && widget.courseId!.isNotEmpty) {
        await CourseService().applyForCourse(
          courseId: widget.courseId!,
          customerName: nameCtrl.text.trim(),
          customerPhone: numberCtrl.text.trim(),
          customerEmail: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
          offerId: widget.offerId,
        );
      }

      if (mounted) {
        String now = DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now());
        appliedCandidates.add({
          "name": nameCtrl.text,
          "number": numberCtrl.text,
          "email": emailCtrl.text,
          "course": widget.course,
          "appliedAt": now,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Applied Successful!!!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.pink,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CoursesScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  /// Validators
  String? validateAlphabet(String? value, String field) {
    if (value == null || value.isEmpty) return "Enter $field";
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return "$field can only contain alphabets";
    }
    return null;
  }

  String? validateNumber(String? value, String field, {int? length}) {
    if (value == null || value.isEmpty) return "Enter $field";
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "$field can only contain numbers";
    }
    if (length != null && value.length != length) {
      return "$field must be $length digits";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Apply for ${widget.course}"),
        centerTitle: true,
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
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),

        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(60),
            ),
            child: Stack(
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
                  filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9), // control blur strength
                  child: Container(
                    color: Colors.white.withOpacity(0.1), // transparent layer to apply blur
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: "Name",
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            prefixIcon: Icon(CupertinoIcons.person, color: Colors.pink),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.pink.shade200,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 2.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          validator: (val) => validateAlphabet(val, "Name"),
                        ),

                        const SizedBox(height: 15),

                        // Phone Number
                        TextFormField(
                          controller: numberCtrl,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            prefixIcon: Icon(CupertinoIcons.phone, color: Colors.pink),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.pink.shade200,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 2.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (val) => validateNumber(val, "Phone Number"),
                        ),

                        const SizedBox(height: 25),

                        TextFormField(
                          controller: emailCtrl,
                          decoration: InputDecoration(
                            labelText: "Email (Optional)",
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(CupertinoIcons.mail, color: Colors.pink),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.pink.shade200,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 2.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return null; // ✅ no error if empty (optional)
                            }
                            // ✅ only validate if something is entered
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(val)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 30,),


                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF0068),
                                    Color(0xFFFF5E49)
                                  ], // purple → deep blue
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4), // shadow position
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // make button transparent
                                  shadowColor: Colors.transparent,     // remove default shadow
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _isSubmitting ? null : submitForm,
                                child: const Text(
                                  "Submit Application",
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
