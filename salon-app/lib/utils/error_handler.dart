import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'guest_guard.dart';

class ErrorHandler {
  static const Color _brandPink = Color(0xFFE91E63);

  static String getMessage(dynamic error) {
    // DioException may wrap ApiException in its error property
    if (error is DioException && error.error is ApiException) {
      return getMessage(error.error as ApiException);
    }
    if (error is ApiException) {
      // Return the actual message from backend first
      // Fall back to status code messages
      switch (error.statusCode) {
        case 400:
          return error.message.isNotEmpty && error.message != 'Unknown error'
              ? error.message
              : 'Invalid request. Please check your input.';
        case 401:
          final msg = error.message.toLowerCase();
          if (msg.contains('authentication') || msg.contains('credentials')) {
            return 'Your session has expired or no authentication was provided.\n\nPlease log in again to continue.';
          }
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
          if (error.message.isNotEmpty && error.message != 'Unknown error') {
            return error.message;
          }
          return 'An unexpected error occurred.';
      }
    }
    // DioException without wrapped ApiException (e.g. from other Dio usage)
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please check your connection and try again.';
        case DioExceptionType.connectionError:
          return 'Connection failed. Please check your internet connection.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.badResponse:
          final res = error.response;
          if (res != null && res.data is Map) {
            final msg = res.data['message'] ?? res.data['error'];
            if (msg != null && msg.toString().isNotEmpty) return msg.toString();
          }
          return 'Server error. Please try again later.';
        default:
          return error.message ?? 'Connection failed. Please check your internet connection.';
      }
    }
    final raw = error?.toString() ?? '';
    if (raw.isNotEmpty && raw != 'null') {
      return 'An unexpected error occurred.\n\n$raw';
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
    final apiEx = error is DioException && error.error is ApiException
        ? error.error as ApiException
        : error is ApiException
            ? error
            : null;
    if (apiEx != null && apiEx.isGuestRestricted) {
      await GuestGuard.showSignupPrompt(
        context,
        actionDescription: guestActionDescription,
      );
      return true;
    }

    await _showThemedDialog(
      context,
      title: 'Something went wrong',
      message: getMessage(error),
    );
    return false;
  }

  /// Legacy sync version - use async show() for guest restriction handling
  static void showSync(BuildContext context, dynamic error) {
    _showThemedDialog(
      context,
      title: 'Something went wrong',
      message: getMessage(error),
    );
  }

  /// Show a simple themed error/info dialog with app branding.
  static Future<void> showMessage(
    BuildContext context, {
    required String message,
    String title = 'Oops',
  }) async {
    await _showThemedDialog(context, title: title, message: message);
  }

  static Future<void> _showThemedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: _brandPink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _brandPink,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
