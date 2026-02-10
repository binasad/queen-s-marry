import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'guest_guard.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is ApiException) {
      // Return the actual message from backend first
      if (error.message.isNotEmpty && error.message != 'Unknown error') {
        return error.message;
      }

      // Fall back to status code messages
      switch (error.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Invalid email or password.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'Resource not found.';
        case 429:
          return 'Too many requests. Please try again later.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred.';
  }

  /// Show error message - automatically handles guest restrictions
  /// Returns true if error was handled as guest restriction
  static Future<bool> show(
    BuildContext context,
    dynamic error, {
    String? guestActionDescription,
  }) async {
    // Check if this is a guest restriction error
    if (error is ApiException && error.isGuestRestricted) {
      await GuestGuard.showSignupPrompt(
        context,
        actionDescription: guestActionDescription,
      );
      return true;
    }

    // Show regular error snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getMessage(error)), backgroundColor: Colors.red),
      );
    }
    return false;
  }

  /// Legacy sync version - use async show() for guest restriction handling
  static void showSync(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getMessage(error)), backgroundColor: Colors.red),
    );
  }
}
