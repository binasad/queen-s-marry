import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../AppScreens/signup.dart';
import 'route_animations.dart';

/// Utility class to handle guest user restrictions
/// Shows signup prompt when guest tries to perform restricted actions
class GuestGuard {
  static final StorageService _storage = const StorageService();

  /// Check if current user is a guest
  static Future<bool> isGuest() async {
    return await _storage.isGuest();
  }

  /// Check if action is allowed for guest user
  /// If guest, shows signup dialog and returns false
  /// If registered user, returns true
  static Future<bool> canPerformAction(
    BuildContext context, {
    String? actionDescription,
  }) async {
    final isGuestUser = await isGuest();

    if (!isGuestUser) {
      return true; // Registered user, allow action
    }

    // Guest user - show signup prompt
    if (context.mounted) {
      await showSignupPrompt(context, actionDescription: actionDescription);
    }
    return false;
  }

  /// Handle API exceptions - shows signup prompt if GUEST_RESTRICTED
  /// Returns true if error was handled (guest restriction)
  /// Returns false if error should be handled by caller
  static Future<bool> handleApiError(
    BuildContext context,
    dynamic error, {
    String? actionDescription,
  }) async {
    if (error is ApiException && error.isGuestRestricted) {
      if (context.mounted) {
        await showSignupPrompt(context, actionDescription: actionDescription);
      }
      return true; // Error was handled
    }
    return false; // Error not handled, caller should handle it
  }

  /// Show signup prompt dialog for guest users
  /// Made public so it can be called from error handlers
  static Future<void> showSignupPrompt(
    BuildContext context, {
    String? actionDescription,
  }) async {
    final description = actionDescription ?? 'perform this action';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: const Color(0xFFE91E63)),
            const SizedBox(width: 10),
            const Text('Create Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To $description, you need to create an account.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Benefits of creating an account:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBenefit('Save your bookings & history'),
            _buildBenefit('Get personalized recommendations'),
            _buildBenefit('Earn loyalty rewards'),
            _buildBenefit('Sync across devices'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).push(slideFromRightRoute(SignupScreen()));
    }
  }

  static Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFFE91E63)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Wrapper for actions that require a registered user
  /// Use this to wrap onPressed callbacks
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
