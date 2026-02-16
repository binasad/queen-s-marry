import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../AppScreens/signup.dart';
import 'route_animations.dart';

/// Utility class to handle guest user restrictions
class GuestGuard {
  static final StorageService _storage = const StorageService();
  static const Color brandPink = Color(0xFFFF0068);

  /// Check if current user is a guest
  static Future<bool> isGuest() async {
    return await _storage.isGuest();
  }

  /// Check if action is allowed for guest user
  static Future<bool> canPerformAction(
    BuildContext context, {
    String? actionDescription,
  }) async {
    final isGuestUser = await isGuest();

    if (!isGuestUser) {
      return true; // Registered user, allow action
    }

    if (context.mounted) {
      await showSignupPrompt(context, actionDescription: actionDescription);
    }
    return false;
  }

  /// Handle API exceptions - shows signup prompt if GUEST_RESTRICTED
  static Future<bool> handleApiError(
    BuildContext context,
    dynamic error, {
    String? actionDescription,
  }) async {
    // Check if the error is a guest restriction from the API
    if (error is ApiException && error.isGuestRestricted) {
      if (context.mounted) {
        await showSignupPrompt(context, actionDescription: actionDescription);
      }
      return true; // Error was handled
    }
    return false; // Error not handled
  }

  /// Show premium signup prompt dialog
  static Future<void> showSignupPrompt(
    BuildContext context, {
    String? actionDescription,
  }) async {
    final description = actionDescription ?? 'perform this action';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brandPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, color: brandPink, size: 20),
            ),
            const SizedBox(width: 12),
            // RESOLVED: Expanded ensures the text wraps and doesn't overflow the screen
            const Expanded(
              child: Text(
                'Account Required',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To $description, you\'ll need to create a free account.',
              style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[500]!.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildBenefit('Save your history & favorites'),
                  _buildBenefit('Access exclusive rewards'),
                  _buildBenefit('Sync across all devices'),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Maybe Later', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPink,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Join Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).push(slideFromRightRoute(const SignupScreen()));
    }
  }

  static Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 16, color: brandPink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
            ),
          ),
        ],
      ),
    );
  }

  static Function()? guardAction(
    BuildContext context,
    Future<void> Function() action, {
    String? actionDescription,
  }) {
    return () async {
      final canProceed = await canPerformAction(
        context,
        actionDescription: actionDescription,
      );
      if (canProceed) {
        await action();
      }
    };
  }
}