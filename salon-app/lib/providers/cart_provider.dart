import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cart_service.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

class CartNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  late final CartService _service;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _service = ref.read(cartServiceProvider);
    return _service.getItems();
  }

  Future<CartAddResult> addService(
    Map<String, dynamic> service, {
    int quantity = 1,
    String? offerId,
    String? offerTitle,
    double? discountedPrice,
    String? scheduledDate,
    String? scheduledTime,
  }) async {
    final result = await _service.addService(
      service,
      quantity: quantity,
      offerId: offerId,
      offerTitle: offerTitle,
      discountedPrice: discountedPrice,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    state = AsyncData(result.items);
    return result;
  }

  Future<void> removeAt(int index) async {
    state = AsyncData(await _service.removeAt(index));
  }

  Future<void> setQuantity(int index, int quantity) async {
    state = AsyncData(await _service.setQuantity(index, quantity));
  }

  Future<void> setSchedule(int index, {required String date, required String time}) async {
    state = AsyncData(await _service.setSchedule(index, date: date, time: time));
  }

  Future<void> clear() async {
    await _service.clear();
    state = const AsyncData([]);
  }
}

final cartProvider =
    AsyncNotifierProvider<CartNotifier, List<Map<String, dynamic>>>(CartNotifier.new);

/// Total quantity (sum). Returns 0 while loading.
final cartCountProvider = Provider<int>((ref) {
  final state = ref.watch(cartProvider);
  return state.maybeWhen(
    data: (items) {
      int total = 0;
      for (final e in items) {
        total += (e['quantity'] as num?)?.toInt() ?? 1;
      }
      return total;
    },
    orElse: () => 0,
  );
});

final cartTotalProvider = Provider<double>((ref) {
  final state = ref.watch(cartProvider);
  final service = ref.watch(cartServiceProvider);
  return state.maybeWhen(
    data: (items) => service.totalOf(items),
    orElse: () => 0,
  );
});
