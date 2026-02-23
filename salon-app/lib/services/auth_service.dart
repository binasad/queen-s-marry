import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'push_notification_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();

  /// Roles allowed to access the mobile app
  static const List<String> _allowedMobileRoles = ['Customer', 'User', 'Guest', 'Admin', 'Owner'];

  /// Guest login - local only, no backend call (works offline, avoids rate limits)
  /// Creates synthetic user, uses local storage for favorites. Session-only.
  Future<Map<String, dynamic>> guestLogin() async {
    debugPrint('AuthService: Guest login (local)');
    await _api.clearTokens();
    await _storage.setGuestStatus(true);

    final user = {
      'id': 'guest_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Guest',
      'email': '',
      'profile_image_url': null,
      'isGuest': true,
      'role': {'name': 'Guest'},
    };
    return user;
  }

  /// Check if current user is a guest (local or backend guest)
  Future<bool> isGuestUser() async {
    return await _storage.isGuest();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
    String? gender,
  }) async {
    try {
      debugPrint('AuthService: Starting registration for $email');
      final response = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (address != null) 'address': address,
        if (gender != null) 'gender': gender,
      }, requiresAuth: false);

      debugPrint('AuthService: Registration response received');
      debugPrint('Response keys: ${response.keys}');

      if (response.containsKey('data')) {
        return response['data'] as Map<String, dynamic>;
      }

      // If response doesn't have 'data' key, return the whole response
      debugPrint(
        'Warning: Response does not have "data" key, returning full response',
      );
      return response;
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Starting login for $email');
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      }, requiresAuth: false);

      debugPrint('AuthService: Login response received');
      debugPrint('Response keys: ${response.keys}');

      if (!response.containsKey('data')) {
        debugPrint('ERROR: Response does not have "data" key!');
        debugPrint('Full response: $response');
        throw Exception('Invalid login response: missing data key');
      }

      final data = response['data'] as Map<String, dynamic>;
      debugPrint('Login response data: $data'); // Debug log

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      debugPrint('Access token received: ${accessToken != null}');
      debugPrint('Refresh token received: ${refreshToken != null}');

      if (accessToken != null && refreshToken != null) {
        await _api.saveTokens(accessToken, refreshToken);
        await _storage.setGuestStatus(false); // Clear guest so favorites use API
        debugPrint('Tokens saved successfully');

        // Verify tokens were saved
        final savedToken = await _api.getAccessToken();
        debugPrint('Token verification: ${savedToken != null}');
        if (savedToken != null) {
          debugPrint('Saved token length: ${savedToken.length}');
        }
      } else {
        debugPrint('ERROR: Tokens not found in login response!');
        debugPrint('Available keys in data: ${data.keys}');
      }

      if (!data.containsKey('user')) {
        debugPrint('ERROR: User data not found in login response!');
        debugPrint('Available keys in data: ${data.keys}');
        throw Exception('Invalid login response: missing user data');
      }

      final user = data['user'] as Map<String, dynamic>;

      // Validate role - only Customer and Guest can access mobile app
      final role = user['role'] as Map<String, dynamic>?;
      final roleName = role?['name']?.toString() ?? '';
      debugPrint('AuthService: User role is: $roleName');

      if (!_allowedMobileRoles.contains(roleName)) {
        // Clear tokens since this user shouldn't have access
        await _api.clearTokens();
        debugPrint('AuthService: Role "$roleName" not allowed on mobile app');
        throw Exception(
          'This account is for staff/admin access only. Please use the web portal to login.',
        );
      }

      return user;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      rethrow;
    }
  }

  Future<void> verifyEmail(String code, String email) async {
    await _api.post('/auth/verify-email', {
      'email': email,
      'code': code,
    }, requiresAuth: false);
  }

  Future<void> resendVerificationEmail(String email) async {
    await _api.post('/auth/resend-verification', {
      'email': email,
    }, requiresAuth: false);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', {
      'email': email,
    }, requiresAuth: false);
  }

  // Request a 6-digit OTP for password reset
  Future<void> sendPasswordResetOtp(String email) async {
    await _api.post('/auth/forgot-password-otp', {
      'email': email,
    }, requiresAuth: false);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post('/auth/reset-password', {
      'token': token,
      'newPassword': newPassword,
    }, requiresAuth: false);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Send OTP for change password (user is already authenticated)
  Future<void> sendChangePasswordOtp() async {
    await _api.post('/auth/send-change-password-otp', {});
  }

  // Change password using OTP verification
  Future<void> changePasswordWithOtp({
    required String code,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password-otp', {
      'code': code,
      'newPassword': newPassword,
    });
  }

  // Complete password reset using email + OTP code
  Future<void> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post('/auth/reset-password-otp', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    }, requiresAuth: false);
  }

  Future<void> logout() async {
    try {
      await PushNotificationService().clearToken();
    } catch (_) {
      // Ignore – user may already be logged out
    }
    await _api.clearTokens();
    await _storage.setGuestStatus(false);
    await _storage.clearCachedProfile();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getAccessToken();
    return token != null;
  }

  /// Google Sign-In - send idToken to backend, get JWT tokens
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await _api.post('/auth/google', {
        'idToken': idToken,
      }, requiresAuth: false);

      if (!response.containsKey('data')) {
        throw Exception('Invalid Google login response');
      }

      final data = response['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _api.saveTokens(accessToken, refreshToken);
        await _storage.setGuestStatus(false);
      }

      if (!data.containsKey('user')) {
        throw Exception('Invalid Google login response: missing user');
      }

      final user = data['user'] as Map<String, dynamic>;
      final role = user['role'] as Map<String, dynamic>?;
      final roleName = role?['name']?.toString() ?? '';

      if (!_allowedMobileRoles.contains(roleName)) {
        await _api.clearTokens();
        throw Exception(
          'This account is for staff/admin access only. Please use the web portal to login.',
        );
      }

      return user;
    } catch (e) {
      debugPrint('AuthService: Google login error: $e');
      // Extract backend message from DioException when available
      if (e is DioException && e.response?.data is Map) {
        final msg = e.response!.data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          throw Exception(msg);
        }
      }
      rethrow;
    }
  }
}
