import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cart storage for services. Persists with SharedPreferences so the
/// cart survives app restarts.
///
/// Item shape:
/// - serviceId: String
/// - service: snapshot map (includes salon info if available)
/// - quantity: int
/// - offerId, offerTitle: optional
/// - basePrice, unitPrice: double
/// - scheduledDate: yyyy-MM-dd (nullable)
/// - scheduledTime: 12-hour label (nullable), e.g. "10:00 am"
/// - addedAt: ISO timestamp
class CartService {
  static const _key = 'cart_items_v2';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> getItems() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Map<String, dynamic>> items) async {
    final prefs = await _prefs;
    await prefs.setString(_key, jsonEncode(items));
  }

  /// Adds a service. Returns a result flag describing what happened so the UI
  /// can choose how to surface the message (added vs increased quantity).
  Future<CartAddResult> addService(
    Map<String, dynamic> service, {
    int quantity = 1,
    String? offerId,
    String? offerTitle,
    double? discountedPrice,
    String? scheduledDate,
    String? scheduledTime,
  }) async {
    final id = service['id']?.toString() ?? '';
    if (id.isEmpty) {
      return CartAddResult(items: await getItems(), wasAlreadyInCart: false);
    }
    // Each Add-to-Cart action creates its own line item so the same service
    // can be booked into multiple separate slots. Duplicates are intentional —
    // dedup by (serviceId + offerId) is NOT done here.
    final items = await getItems();
    final basePrice = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
    items.add({
      'serviceId': id,
      'service': service,
      'quantity': quantity,
      'offerId': offerId,
      'offerTitle': offerTitle,
      'basePrice': basePrice,
      'unitPrice': discountedPrice ?? basePrice,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'addedAt': DateTime.now().toIso8601String(),
    });
    await _save(items);
    return CartAddResult(items: items, wasAlreadyInCart: false);
  }

  Future<List<Map<String, dynamic>>> removeAt(int index) async {
    final items = await getItems();
    if (index < 0 || index >= items.length) return items;
    items.removeAt(index);
    await _save(items);
    return items;
  }

  Future<List<Map<String, dynamic>>> setQuantity(int index, int quantity) async {
    final items = await getItems();
    if (index < 0 || index >= items.length) return items;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index]['quantity'] = quantity;
    }
    await _save(items);
    return items;
  }

  Future<List<Map<String, dynamic>>> setSchedule(
    int index, {
    required String date,
    required String time,
  }) async {
    final items = await getItems();
    if (index < 0 || index >= items.length) return items;
    items[index]['scheduledDate'] = date;
    items[index]['scheduledTime'] = time;
    await _save(items);
    return items;
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_key);
  }

  Future<bool> contains(String serviceId) async {
    final items = await getItems();
    return items.any((e) => e['serviceId'] == serviceId);
  }

  double totalOf(List<Map<String, dynamic>> items) {
    double total = 0;
    for (final e in items) {
      final qty = (e['quantity'] as num?)?.toInt() ?? 1;
      final unit = (e['unitPrice'] as num?)?.toDouble() ??
          double.tryParse(e['unitPrice']?.toString() ?? '0') ??
          0;
      total += unit * qty;
    }
    return total;
  }
}

class CartAddResult {
  final List<Map<String, dynamic>> items;
  final bool wasAlreadyInCart;
  CartAddResult({required this.items, required this.wasAlreadyInCart});
}
