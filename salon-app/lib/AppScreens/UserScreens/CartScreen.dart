import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../services/appointment_service.dart';
import '../../services/user_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/haptic_feedback.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/schedule_picker_sheet.dart';
import '../Services/servicesdetails.dart';
import 'AppointmentList.dart';
import 'JazzCashPaymentScreen.dart';

const _kPrimary = Color(0xFFFF0068);
const _kAccent = Color(0xFFFF6CBF);
const _kBg = Color(0xFFFBFBFD);

/// Cart screen: list of services, per-item schedule editor, payment method
/// selector, single "Book Now" CTA that processes each item via the existing
/// JazzCash / Stripe flow and navigates to My Bookings on success.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final ApiService _api = ApiService();
  final UserService _userService = UserService();
  final AppointmentService _appointments = AppointmentService();

  String _paymentMethod = 'jazzcash'; // 'jazzcash' | 'stripe'
  bool _processing = false;
  String? _userName, _userEmail, _userPhone;

  static const List<String> _timeSlots = [
    '9:00 am', '10:00 am', '11:00 am', '12:00 pm',
    '2:00 pm', '3:00 pm', '4:00 pm', '5:00 pm',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await _userService.getProfile();
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null && mounted) {
        setState(() {
          _userName = user['name']?.toString();
          _userEmail = user['email']?.toString();
          _userPhone = user['phone']?.toString();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          cartAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear cart',
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.black54),
                    onPressed: _confirmClear,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
        error: (e, _) => Center(child: Text('Failed to load cart: $e')),
        data: (items) {
          if (items.isEmpty) return _buildEmptyState();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 260),
            physics: const BouncingScrollPhysics(),
            children: [
              for (var i = 0; i < items.length; i++)
                _CartItemCard(
                  item: items[i],
                  index: i,
                  timeSlots: _timeSlots,
                ),
              const SizedBox(height: 8),
              _buildPaymentSection(),
            ],
          );
        },
      ),
      bottomSheet: cartAsync.maybeWhen(
        data: (items) => items.isEmpty
            ? null
            : _buildCheckoutBar(items, total),
        orElse: () => null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 96, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text('Your cart is empty',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Add services from the catalog to book them together.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Browse services', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Choose how to pay', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 14),
          _buildPaymentOption(
            value: 'jazzcash',
            title: 'JazzCash',
            subtitle: 'Debit / Credit Card via JazzCash',
            icon: Icons.credit_card,
            color: const Color(0xFFE2001A),
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            value: 'stripe',
            title: 'Card (International)',
            subtitle: 'Visa, Mastercard via Stripe',
            icon: Icons.payment,
            color: const Color(0xFF6772E5),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        HapticHelper.lightImpact();
        setState(() => _paymentMethod = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.18),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(List<Map<String, dynamic>> items, double total) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total (${items.length} item${items.length == 1 ? '' : 's'})',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('PKR ${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Text(
                  _paymentMethod == 'jazzcash' ? 'JazzCash' : 'Card',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                onPressed: _processing ? null : () => _bookNow(items),
                child: _processing
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('Book Now',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Booking flow ───────────────────────────
  //
  // Design: one combined payment for the running total covers the entire cart.
  //   1. The first cart item acts as the "anchor" — the existing
  //      `/payments/*` endpoint always couples the transaction to one service,
  //      and the backend creates that appointment automatically on success.
  //   2. After the single payment succeeds, every other cart item is created
  //      via `POST /appointments` with `payNow: true` so they're recorded as
  //      paid alongside the anchor.
  //   3. Cart is cleared and the user is taken to "My Bookings".

  Future<void> _bookNow(List<Map<String, dynamic>> items) async {
    // Every item must already have a schedule (we enforce this at Add-to-Cart
    // time, but guard against legacy items that pre-date the change).
    for (var i = 0; i < items.length; i++) {
      final d = items[i]['scheduledDate'];
      final t = items[i]['scheduledTime'];
      if (d == null || (d is String && d.isEmpty) || t == null || (t is String && t.isEmpty)) {
        _toast('Please set date & time for "${items[i]['service']['name']}"', Colors.orange);
        return;
      }
    }

    final email = (_userEmail ?? '').trim();
    final phone = (_userPhone ?? '').trim();
    if (email.isEmpty || phone.isEmpty) {
      _toast('Please complete your profile (email & phone) before booking.', Colors.orange);
      return;
    }

    HapticHelper.mediumImpact();
    setState(() => _processing = true);

    try {
      final totalAmount = ref.read(cartTotalProvider);
      if (totalAmount <= 0) {
        _toast('Cart total is zero — nothing to charge.', Colors.orange);
        return;
      }

      final paid = _paymentMethod == 'jazzcash'
          ? await _payJazzCashTotal(items, totalAmount)
          : await _payStripeTotal(items, totalAmount);

      if (!paid) {
        // Cancelled or failed in payment sheet — bail out, keep cart intact.
        return;
      }

      // Create the secondary appointments (items 1..n). The anchor (items[0])
      // is created server-side by the payment webhook / confirm step.
      int extraBooked = 0;
      for (var i = 1; i < items.length; i++) {
        try {
          await _createPaidAppointment(items[i]);
          extraBooked += 1;
        } catch (e) {
          debugPrint('⚠️ Failed to create secondary appointment $i: $e');
        }
      }

      await ref.read(cartProvider.notifier).clear();
      if (mounted) _showSuccessDialog(1 + extraBooked);
    } catch (e) {
      if (e is StripeException) {
        _toast('Payment cancelled', Colors.orange);
      } else if (mounted) {
        ErrorHandler.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// One Stripe Payment Sheet charging the cart total. The anchor service's
  /// id/date/time is attached so the existing webhook creates that appointment.
  Future<bool> _payStripeTotal(List<Map<String, dynamic>> items, double total) async {
    final anchor = items.first;
    final anchorService = Map<String, dynamic>.from(anchor['service'] as Map);
    final cents = (total * 100).round().clamp(100, 999999999);

    final intent = await _api.post('/payments/create-intent', {
      'amount': cents,
      'currency': 'pkr',
      'serviceId': anchorService['id'].toString(),
      'appointmentDate': anchor['scheduledDate'].toString(),
      'appointmentTime': _convertTo24Hour(anchor['scheduledTime'].toString()),
      'customerName': _userName ?? 'Customer',
      'customerEmail': _userEmail ?? '',
      'customerPhone': _userPhone ?? '',
      if ((anchor['offerId']?.toString() ?? '').isNotEmpty)
        'offerId': anchor['offerId'].toString(),
    });

    final clientSecret = intent['clientSecret'];
    final paymentIntentId = intent['paymentIntentId'];

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Queens Marry Salon',
        style: ThemeMode.light,
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    if (paymentIntentId != null && paymentIntentId.toString().isNotEmpty) {
      try {
        await _api.post('/payments/confirm-appointment', {
          'paymentIntentId': paymentIntentId,
        });
      } catch (_) {
        // Webhook may have created it; ignore.
      }
    }
    return true;
  }

  /// One JazzCash checkout session charging the cart total. The anchor service
  /// is attached so the backend creates that appointment on success.
  Future<bool> _payJazzCashTotal(List<Map<String, dynamic>> items, double total) async {
    final anchor = items.first;
    final anchorService = Map<String, dynamic>.from(anchor['service'] as Map);
    final amountInPaisa = (total * 100).round();

    final response = await _api.post('/payments/jazzcash/initiate', {
      'amount': amountInPaisa,
      'serviceId': anchorService['id'].toString(),
      'appointmentDate': anchor['scheduledDate'].toString(),
      'appointmentTime': _convertTo24Hour(anchor['scheduledTime'].toString()),
      'customerName': _userName ?? 'Customer',
      'customerEmail': _userEmail ?? '',
      'customerPhone': _userPhone ?? '',
      if ((anchor['offerId']?.toString() ?? '').isNotEmpty)
        'offerId': anchor['offerId'].toString(),
    });

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to initiate JazzCash payment');
    }
    final checkoutHtml = response['checkoutHtml'] as String?;
    if (checkoutHtml == null || checkoutHtml.isEmpty) {
      throw Exception('JazzCash checkout HTML missing in response');
    }
    if (!mounted) return false;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => JazzCashPaymentScreen(
          checkoutHtml: checkoutHtml,
          returnUrlBase: 'payment-',
        ),
      ),
    );
    return result == 'success';
  }

  /// Create a paid appointment record for a non-anchor cart item.
  ///
  /// Backend's `POST /appointments` with `payNow: true` already (a) marks the
  /// row paid + confirmed, (b) emits the WebSocket events, and (c) sends the
  /// push notification + confirmation email. No follow-up `markAsPaid` call is
  /// needed — and that endpoint is admin-only anyway.
  Future<void> _createPaidAppointment(Map<String, dynamic> item) async {
    final service = Map<String, dynamic>.from(item['service'] as Map);
    final offerId = item['offerId']?.toString();
    await _appointments.createAppointment(
      serviceId: service['id'].toString(),
      appointmentDate: item['scheduledDate'].toString(),
      appointmentTime: _convertTo24Hour(item['scheduledTime'].toString()),
      customerName: _userName ?? 'Customer',
      customerEmail: _userEmail ?? '',
      customerPhone: _userPhone ?? '',
      payNow: true,
      paymentMethod: _paymentMethod, // 'jazzcash' | 'stripe' (validator now accepts both)
      offerId: offerId,
    );
  }

  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/salon_welcome.json',
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 20),
            const Text('Booking Confirmed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              '$count ${count == 1 ? 'appointment has' : 'appointments have'} been placed successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context); // close cart
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppointmentsListScreen()),
                  );
                },
                child: const Text('View My Bookings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Continue browsing',
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes all items from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartProvider.notifier).clear();
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _convertTo24Hour(String time12h) {
    final t = time12h.trim().toLowerCase();
    if (!t.contains('am') && !t.contains('pm')) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time12h.trim());
      if (m != null) return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)!}';
      return time12h;
    }
    final isPm = t.contains('pm');
    final hhmm = time12h.replaceAll(RegExp(r'\s*[ap]m\s*', caseSensitive: false), '');
    final parts = hhmm.split(':');
    final mStr = parts.length > 1 ? parts[1].trim() : '00';
    int hour = int.tryParse(parts[0].trim()) ?? 12;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${mStr.padLeft(2, '0')}';
  }
}

// ─────────────────────────── Cart item card ───────────────────────────

class _CartItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final int index;
  final List<String> timeSlots;

  const _CartItemCard({
    required this.item,
    required this.index,
    required this.timeSlots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = Map<String, dynamic>.from(item['service'] as Map);
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final offerTitle = item['offerTitle']?.toString();
    final dateStr = item['scheduledDate']?.toString();
    final timeStr = item['scheduledTime']?.toString();
    final salon = service['salon_name']?.toString() ??
        service['salonName']?.toString() ??
        'Queens Marry Salon';

    return Dismissible(
      key: ValueKey('cart-$index-${item['serviceId']}-${item['offerId']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(cartProvider.notifier).removeAt(index),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiceDetailedScreen(service: service)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImage(service),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service['name']?.toString() ?? 'Service',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.storefront_outlined, size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                salon,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        if (offerTitle != null && offerTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer, size: 12, color: _kAccent),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    offerTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _kAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'PKR ${(unitPrice * qty).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                    onPressed: () => ref.read(cartProvider.notifier).removeAt(index),
                    tooltip: 'Remove',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ScheduleChip(
                      dateStr: dateStr,
                      timeStr: timeStr,
                      onTap: () => _openScheduleSheet(context, ref, index, dateStr, timeStr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _QtyStepper(
                    quantity: qty,
                    onMinus: () => ref.read(cartProvider.notifier).setQuantity(index, qty - 1),
                    onPlus: () => ref.read(cartProvider.notifier).setQuantity(index, qty + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> s) {
    final url = s['image_url']?.toString() ?? s['image']?.toString() ?? '';
    const w = 72.0, h = 72.0;
    if (url.isEmpty) {
      return Image.asset('assets/FeatherCutting.png', width: w, height: h, fit: BoxFit.cover);
    }
    if (url.startsWith('http')) {
      return CachedImageWidget(imageUrl: url, width: w, height: h, fit: BoxFit.cover);
    }
    return Image.asset(url, width: w, height: h, fit: BoxFit.cover);
  }

  Future<void> _openScheduleSheet(
    BuildContext context,
    WidgetRef ref,
    int index,
    String? currentDate,
    String? currentTime,
  ) async {
    final result = await showSchedulePickerSheet(
      context,
      initialDate: currentDate,
      initialTime: currentTime,
      title: 'Edit schedule',
      subtitle: 'Update the date and time for this service',
      confirmLabel: 'Save schedule',
      timeSlots: timeSlots,
    );
    if (result != null) {
      await ref
          .read(cartProvider.notifier)
          .setSchedule(index, date: result.date, time: result.time);
    }
  }
}

class _ScheduleChip extends StatelessWidget {
  final String? dateStr;
  final String? timeStr;
  final VoidCallback onTap;
  const _ScheduleChip({required this.dateStr, required this.timeStr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSchedule = dateStr != null && dateStr!.isNotEmpty && timeStr != null && timeStr!.isNotEmpty;
    String label;
    if (hasSchedule) {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(dateStr!);
        label = '${DateFormat('EEE, MMM d').format(d)} · $timeStr';
      } catch (_) {
        label = '$dateStr · $timeStr';
      }
    } else {
      label = 'Set schedule';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasSchedule ? _kAccent.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasSchedule ? _kAccent.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSchedule ? Icons.event_available : Icons.event_note,
              size: 16,
              color: hasSchedule ? _kAccent : Colors.orange[800],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasSchedule ? _kAccent : Colors.orange[800],
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QtyStepper({required this.quantity, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('$quantity',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          _stepBtn(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkResponse(
      onTap: () {
        HapticHelper.lightImpact();
        onTap();
      },
      radius: 18,
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
