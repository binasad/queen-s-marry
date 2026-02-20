import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'guest_guard.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    // DioException may wrap ApiException in its error property
    if (error is DioException && error.error is ApiException) {
      return getMessage(error.error as ApiException);
    }
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
