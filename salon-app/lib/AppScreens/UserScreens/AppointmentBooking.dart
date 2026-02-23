import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:lottie/lottie.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../utils/error_handler.dart';
import '../PersonalInfo.dart';

class AppColors {
  static const Color primaryPink = Color(0xFFFF0068);
  static const Color accentPeach = Color(0xFFFFC371);
  static const Color background = Color(0xFFFBFBFD);
  static const Color glassWhite = Color(0xCCFFFFFF);

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFF0068), Color(0xFFFF5E93)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppointmentBookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final String? offerId;
  final double? offerDiscountedPrice;

  const AppointmentBookingScreen({
    super.key,
    required this.service,
    this.offerId,
    this.offerDiscountedPrice,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final UserService _userService = UserService();
  final ApiService _api = ApiService();

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  bool _isLoading = false;
  String? _userEmail, _userName, _userPhone;
  List<DateTime> _dates = [];

  final List<String> _timeSlots = [
    '9:00 am',
    '10:00 am',
    '11:00 am',
    '12:00 pm',
    '2:00 pm',
    '3:00 pm',
    '4:00 pm',
    '5:00 pm',
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

  String _convertTo24Hour(String time12h) {
    final t = time12h.trim().toLowerCase();
    if (t.contains('am') || t.contains('pm')) return _parseAmPm(time12h);
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time12h.trim());
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}';
    }
    return time12h;
  }

  String _parseAmPm(String time) {
    final t = time.toLowerCase();
    final isPm = t.contains('pm');
    final hhmm = time.replaceAll(
      RegExp(r'\s*[ap]m\s*', caseSensitive: false),
      '',
    );
    final parts = hhmm.split(':');
    final mStr = parts.length > 1 ? parts[1].trim() : '00';
    int hour = int.tryParse(parts[0].trim()) ?? 12;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${mStr.padLeft(2, '0')}';
  }

  double _getStandardPrice() {
    // Use _base_price when present (from offer flow) for correct Standard Rate display
    final base = widget.service['_base_price'];
    if (base != null) {
      return double.tryParse(base.toString()) ?? 0.0;
    }
    return double.tryParse(widget.service['price']?.toString() ?? '0') ?? 0.0;
  }
  double _getFinalPrice() => widget.offerDiscountedPrice ?? _getStandardPrice();
  double _getChargeAmount() => _getFinalPrice();

  Future<void> _bookAppointment() async {
    if (_selectedTimeIndex == -1) {
      _showSnackBar('Please select a time', Colors.orange);
      return;
    }

    final phone = _userPhone?.trim() ?? '';
    final email = _userEmail?.trim() ?? '';
    if (phone.isEmpty || email.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Complete Profile'),
            content: Text(
              phone.isEmpty
                  ? 'Please add your phone number in Settings to complete your booking.'
                  : 'Please add your email in Settings to complete your booking.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserPersonalInfo(),
                    ),
                  );
                },
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedDate = _dates[_selectedDateIndex];
      final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final String rawTimeLabel = _timeSlots[_selectedTimeIndex];
      final String timeStr = _convertTo24Hour(rawTimeLabel);

      final double price = _getChargeAmount();
      final int amountInCents = (price * 100).round().clamp(100, 999999999);

      // Create PaymentIntent with booking metadata - webhook will create appointment on success
      final paymentIntentResponse = await _api.post('/payments/create-intent', {
        'amount': amountInCents,
        'currency': 'pkr',
        'serviceId': widget.service['id'].toString(),
        'appointmentDate': dateStr,
        'appointmentTime': timeStr,
        'customerName': _userName ?? 'Customer',
        'customerEmail': _userEmail ?? '',
        'customerPhone': _userPhone ?? '',
        if (widget.offerId != null && widget.offerId!.isNotEmpty) 'offerId': widget.offerId,
      });

      final clientSecret = paymentIntentResponse['clientSecret'];
      final paymentIntentId = paymentIntentResponse['paymentIntentId'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Aztrosys Salon',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Payment verified by Stripe - create appointment (fallback if webhook hasn't)
      debugPrint('✅ Payment Successful. Creating appointment...');
      if (paymentIntentId != null && paymentIntentId.toString().isNotEmpty) {
        try {
          await _api.post('/payments/confirm-appointment', {
            'paymentIntentId': paymentIntentId,
          });
          debugPrint('✅ Appointment created.');
        } catch (e) {
          debugPrint('⚠️ confirm-appointment: $e (webhook may have created it)');
        }
      }

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (e is StripeException) {
        _showSnackBar("Payment Cancelled", Colors.orange);
      } else {
        debugPrint('❌ Booking Error: $e');
        if (mounted) ErrorHandler.show(context, e);
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
            Lottie.asset(
              'assets/salon_welcome.json',
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 80,
              ),
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
                  Navigator.pop(context);
                  Navigator.pop(context);
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
      body: Stack(
        children: [
          _buildHeroBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildServiceSummaryCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          "Schedule",
                          "Choose your preferred date",
                        ),
                        _buildDateList(),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          "Time Slot",
                          "Available booking hours",
                        ),
                        _buildTimeGrid(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFloatingBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Positioned(
      top: -100,
      right: -50,
      child: CircleAvatar(
        radius: 150,
        backgroundColor: AppColors.primaryPink.withOpacity(0.05),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          const Text(
            "Booking Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildServiceSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service['name'] ?? 'Treatment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Professional Service",
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _buildPriceRow(
            "Standard Rate",
            "PKR ${_getStandardPrice().toStringAsFixed(0)}",
            isDimmed: true,
          ),
          if (widget.offerId != null)
            _buildPriceRow(
              "Offer Discount",
              "- PKR ${(_getStandardPrice() - _getFinalPrice()).toStringAsFixed(0)}",
              isDiscount: true,
            ),
          _buildPriceRow(
            "Total Payable",
            "PKR ${_getFinalPrice().toStringAsFixed(0)}",
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isDimmed = false,
    bool isDiscount = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top if text wraps
        children: [
          // Wrap the label in Expanded to prevent it from pushing the price off-screen
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDimmed ? Colors.grey[500] : Colors.black87,
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12), // Minimum gap between label and price
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDiscount
                  ? Colors.green
                  : (isBold ? AppColors.primaryPink : Colors.black),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              fontSize: isBold ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(sub, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDateList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 300,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDateIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.premiumGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(_dates[index]),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(_dates[index]),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
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

  Widget _buildTimeGrid() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: _timeSlots.asMap().entries.map((entry) {
        final isSelected = _selectedTimeIndex == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeIndex = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryPink : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryPink
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _bookAppointment,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6CBF),
                      const Color(0xFFFF8E9E),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6CBF).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          "Complete Booking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
