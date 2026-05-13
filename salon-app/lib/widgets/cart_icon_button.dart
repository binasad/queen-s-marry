import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../AppScreens/UserScreens/CartScreen.dart';

/// Reusable cart icon with a live badge of total items. Designed to drop into
/// any AppBar's `actions` or as a stand-alone icon button inside a header row.
class CartIconButton extends ConsumerWidget {
  final Color? iconColor;
  final double iconSize;
  final EdgeInsets padding;

  const CartIconButton({
    super.key,
    this.iconColor,
    this.iconSize = 26,
    this.padding = const EdgeInsets.only(right: 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final color = iconColor ?? Theme.of(context).iconTheme.color ?? Colors.black87;

    return Padding(
      padding: padding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_bag_outlined, color: color, size: iconSize),
            if (count > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0068),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
