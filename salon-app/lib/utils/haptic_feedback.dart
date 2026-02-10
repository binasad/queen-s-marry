import 'package:flutter/services.dart';

/// Haptic feedback helper
class HapticHelper {
  /// Light impact (for taps, selections)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact (for button presses)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact (for important actions)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback (for switches, toggles)
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate (for errors, warnings)
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
