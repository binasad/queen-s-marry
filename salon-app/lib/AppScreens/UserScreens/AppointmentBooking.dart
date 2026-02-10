import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for CupertinoActivityIndicator
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show StripeException;
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../utils/guest_guard.dart';

class AppColors {
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color lightPink = Color(0xFFF48FB1);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [lightPink, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color background = Color(0xFFF8F9FD);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLightGrey = Color(0xFFAAB0B7);
}

class AppointmentBookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const AppointmentBookingScreen({Key? key, required this.service})
    : super(key: key);

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final UserService _userService = UserService();
  final ApiService _api = ApiService();

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  bool _isLoading = false;

  String? _userEmail;
  String? _userName;
  String? _userPhone;

  List<DateTime> _dates = [];

  final List<String> _timeSlots = [
    '7:00 am',
    '8:00 am',
    '9:00 am',
    '10:00 am',
    '11:00 am',
    '12:00 pm',
    '1:00 pm',
    '2:00 pm',
    '3:00 pm',
    '4:00 pm',
    '5:00 pm',
    '6:00 pm',
  ];

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadUserData();
  }

  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (index) => now.add(Duration(days: index)));
  }

  Future<void> _loadUserData() async {
    try {
      final profileData = await _userService.getProfile();
      final user = profileData['user'] as Map<String, dynamic>?;
      if (user != null && mounted) {
        setState(() {
          _userEmail = user['email']?.toString() ?? '';
          _userPhone = user['phone']?.toString() ?? '';
          _userName = user['name']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// CRITICAL FIX: Converts "8:00 am" to "08:00" to satisfy backend HH:MM validator
  /// CRITICAL: Forces "11:00 am" -> "11:00" and "2:00 pm" -> "14:00"
  String _convertTo24Hour(String time12h) {
    try {
      // 1. Clean the string
      final input = time12h.toLowerCase().trim();

      // 2. Use DateFormat to parse h:mm a (e.g. 1:00 pm)
      final DateFormat format12 = DateFormat('h:mm a');

      // 3. Use DateFormat HH:mm to output 24hr (e.g. 13:00)
      final DateFormat format24 = DateFormat('HH:mm');

      final DateTime dateTime = format12.parse(input);
      return format24.format(dateTime);
    } catch (e) {
      debugPrint('❌ Time Conversion Error: $e');
      // Manual fallback if intl fails
      return _manualTimeFix(time12h);
    }
  }

  String _manualTimeFix(String time) {
    // Basic fallback for common slots if DateFormat fails
    if (time.contains('am')) return time.replaceAll(' am', '').padLeft(5, '0');
    if (time.contains('pm')) {
      int hour = int.parse(time.split(':')[0]);
      if (hour != 12) hour += 12;
      return "$hour:${time.split(':')[1].replaceAll(' pm', '')}";
    }
    return time;
  }

  Future<void> _bookAppointment() async {
    if (_selectedTimeIndex == -1) {
      _showSnackBar('Please select a time', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- STEP 1: PREPARE DATA ---
      final selectedDate = _dates[_selectedDateIndex];
      final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final String rawTimeLabel = _timeSlots[_selectedTimeIndex];
      final String timeStr = _convertTo24Hour(rawTimeLabel);

      // Calculate amount in cents (Stripe expects integers: e.g., 1000 PKR = 100000 cents)
      final double price =
          double.tryParse(widget.service['price'].toString()) ?? 0.0;
      final int amountInCents = (price * 100).toInt();

      // --- STEP 2: CREATE STRIPE PAYMENT INTENT ---
      // This calls your backend to get the 'clientSecret'
      final paymentIntentResponse = await _api.post('/payments/create-intent', {
        'amount': amountInCents,
        'currency': 'pkr',
      });

      final clientSecret = paymentIntentResponse['clientSecret'];

      // --- STEP 3: INITIALIZE & PRESENT STRIPE SHEET ---
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Aztrosys Salon',
          style: ThemeMode.light,
        ),
      );

      // Show the payment UI
      await Stripe.instance.presentPaymentSheet();

      // --- STEP 4: FINAL API CALL (If payment succeeded) ---
      debugPrint(
        '✅ Payment Successful. Sending to Backend: Date: $dateStr, Time: $timeStr',
      );

      await _appointmentService.createAppointment(
        serviceId: widget.service['id'].toString(),
        appointmentDate: dateStr,
        appointmentTime: timeStr,
        customerName: _userName ?? 'Customer',
        customerPhone: _userPhone ?? '',
        customerEmail: _userEmail ?? '',
        payNow: true, // Set to true because payment was successful
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (e is StripeException) {
        _showSnackBar("Payment Cancelled", Colors.orange);
      } else {
        debugPrint('❌ Booking Error: $e');
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "Booking Confirmed",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your appointment has been successfully placed.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to home/services
                },
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Book Session",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServicePreview(),
                  _buildSectionTitle("Select Date"),
                  _buildDateSelector(),
                  const SizedBox(height: 10),
                  _buildSectionTitle("Available Time Slots"),
                  _buildTimeSelector(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildServicePreview() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.lightPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryPink,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service['name'] ?? 'Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "PKR ${widget.service['price']}",
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = index == _selectedDateIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: 70,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _timeSlots.asMap().entries.map((entry) {
          final isSelected = entry.key == _selectedTimeIndex;
          return ChoiceChip(
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(entry.value),
            ),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedTimeIndex = entry.key),
            selectedColor: AppColors.primaryPink,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            elevation: 0,
            pressElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey[200]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shadowColor: AppColors.primaryPink.withOpacity(0.4),
            elevation: 10,
          ),
          onPressed: _isLoading ? null : _bookAppointment,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 12,
                    )
                  : const Text(
                      "Complete Booking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
