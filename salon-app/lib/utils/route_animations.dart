import 'package:flutter/material.dart';

/// Common page transition animations to keep navigation feeling polished
/// and consistent across the app.

/// Seamless fade – great for splash → loginOption / onboarding → loginOption.
Route<T> fadeThroughRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Smooth slide from right – perfect for login / signup flows.
Route<T> slideFromRightRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutQuint;

      final tween = Tween<Offset>(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

/// Smooth fade + slide up – for login/guest → home.
Route<T> fadeSlideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final fade = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: curve));
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).chain(CurveTween(curve: curve));
      return FadeTransition(
        opacity: animation.drive(fade),
        child: SlideTransition(
          position: animation.drive(slide),
          child: child,
        ),
      );
    },
  );
}
