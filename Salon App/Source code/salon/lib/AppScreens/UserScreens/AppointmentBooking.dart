import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Manager/AppointmentManager.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const AppointmentBookingScreen({Key? key, required this.service})
      : super(key: key);

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6CBF), // header background + selected date color
              onPrimary: Colors.white,    // header text color
              onSurface: Colors.black,    // default text color
            ),
            dialogBackgroundColor: Colors.white, // background of the date picker
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dateController.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }


  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6CBF), // clock dial + buttons
              onPrimary: Colors.white,    // text on selected dial
              onSurface: Colors.black,    // default text color
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Color(0xFFFFE1F0),
              hourMinuteTextColor: Colors.black,
              dialBackgroundColor: Color(0xFFFFE1F0),
              dialHandColor: Color(0xFFFF6CBF),
              dayPeriodColor: Color(0xFFFFE1F0),        // AM/PM background
              dayPeriodTextColor: Colors.black,         // AM/PM text color
              dayPeriodShape: RoundedRectangleBorder(   // Optional: rounded AM/PM buttons
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }


  void _bookAppointment() {
    if (_formKey.currentState!.validate()) {
      AppointmentManager.addAppointment(
        Appointment(
          serviceName: widget.service['name'],
          name: _nameController.text,
          date: _dateController.text,
          time: _timeController.text,
          phone: _phoneController.text,
        ),
      );

      Navigator.pop(context); // go back to ServiceDetailScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment booked successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.service['name']} Appointment",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
          child: Stack(
            children:[
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
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ListView(
                  children: [
                    _buildStyledTextField(
                      controller: _nameController,
                      label: "Your Name",
                      icon: CupertinoIcons.person,
                      validator: (val) => val!.isEmpty ? "Enter your name" : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                    ),

                    const SizedBox(height: 16),
          
                    _buildStyledTextField(
                      controller: _dateController,
                      label: "Date",
                      icon: CupertinoIcons.calendar_today,
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (val) => val!.isEmpty ? "Pick a date" : null,
                    ),
                    const SizedBox(height: 16),
          
                    _buildStyledTextField(
                      controller: _timeController,
                      label: "Time",
                      icon: CupertinoIcons.time,
                      readOnly: true,
                      onTap: _pickTime,
                      validator: (val) => val!.isEmpty ? "Pick a time" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildStyledTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: CupertinoIcons.phone_arrow_down_left,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val!.isEmpty ? "Enter phone number" : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),

                    const SizedBox(height: 60),
          
                    // Styled Button
                    SizedBox(
                      height: 90,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                        child: ElevatedButton(
                          onPressed: _bookAppointment,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // ensures Ink fills fully
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black,
                            backgroundColor: Colors.transparent, // must be transparent
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6CBF), Color(0xFFFFC371)], // pink to peach
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                "Book Appointment",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
          
                  ],
                ),
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

Widget _buildStyledTextField({
  required TextEditingController controller,
  required String label,
  String? Function(String?)? validator,
  IconData? icon,
  bool readOnly = false,
  TextInputType keyboardType = TextInputType.text,
  void Function()? onTap,
  List<TextInputFormatter>? inputFormatters, // <-- new parameter
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    keyboardType: keyboardType,
    validator: validator,
    onTap: onTap,
    inputFormatters: inputFormatters, // <-- apply formatters
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.pink) : null,
      filled: true,
      fillColor: Colors.grey.shade300,
      labelStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.pink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    ),
  );
}

