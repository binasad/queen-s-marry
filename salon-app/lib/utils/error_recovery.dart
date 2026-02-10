import 'dart:async';
import 'dart:math';

/// Error recovery with exponential backoff
class ErrorRecovery {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  /// Retry a function with exponential backoff
  static Future<T?> retryWithBackoff<T>({
    required Future<T> Function() operation,
    bool Function(dynamic error)? shouldRetry,
    int maxAttempts = maxRetries,
    Duration baseDelay = initialDelay,
  }) async {
    int attempt = 0;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // If this was the last attempt, rethrow
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        // Calculate exponential backoff delay
        final delay = baseDelay * pow(2, attempt - 1);
        await Future.delayed(delay);
      }
    }
    
    return null;
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    // Network errors are usually retryable
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket');
  }
}
