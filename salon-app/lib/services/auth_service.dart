import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = const StorageService();

  /// Roles allowed to access the mobile app
  static const List<String> _allowedMobileRoles = ['Customer', 'User', 'Guest', 'Admin', 'Owner'];

  /// Guest login - creates a temporary user on the backend
  /// Returns user data with isGuest flag
  Future<Map<String, dynamic>> guestLogin() async {
    try {
      print('AuthService: Starting guest login');
      final response = await _api.post('/auth/guest', {}, requiresAuth: false);

      print('AuthService: Guest login response received');
      print('Response keys: ${response.keys}');

      if (!response.containsKey('data')) {
        print('ERROR: Response does not have "data" key!');
        throw Exception('Invalid guest login response: missing data key');
      }

      final data = response['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _api.saveTokens(accessToken, refreshToken);
        // Save guest status
        await _storage.setGuestStatus(true);
        print('Guest tokens saved successfully');
      } else {
        throw Exception('Invalid guest login response: missing tokens');
      }

      // Add isGuest flag to user data
      final user = data['user'] as Map<String, dynamic>;
      user['isGuest'] = true;

      return user;
    } catch (e) {
      print('AuthService: Guest login error: $e');
      rethrow;
    }
  }

  /// Check if current user is a guest
  Future<bool> isGuestUser() async {
    final token = await _api.getAccessToken();
    if (token == null) return false;

    // Check stored guest status
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
      print('AuthService: Starting registration for $email');
      final response = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (address != null) 'address': address,
        if (gender != null) 'gender': gender,
      }, requiresAuth: false);

      print('AuthService: Registration response received');
      print('Response keys: ${response.keys}');

      if (response.containsKey('data')) {
        return response['data'] as Map<String, dynamic>;
      }

      // If response doesn't have 'data' key, return the whole response
      print(
        'Warning: Response does not have "data" key, returning full response',
      );
      return response;
    } catch (e) {
      print('AuthService: Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Starting login for $email');
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      }, requiresAuth: false);

      print('AuthService: Login response received');
      print('Response keys: ${response.keys}');

      if (!response.containsKey('data')) {
        print('ERROR: Response does not have "data" key!');
        print('Full response: $response');
        throw Exception('Invalid login response: missing data key');
      }

      final data = response['data'] as Map<String, dynamic>;
      print('Login response data: $data'); // Debug log

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      print('Access token received: ${accessToken != null}');
      print('Refresh token received: ${refreshToken != null}');

      if (accessToken != null && refreshToken != null) {
        await _api.saveTokens(accessToken, refreshToken);
        print('Tokens saved successfully');

        // Verify tokens were saved
        final savedToken = await _api.getAccessToken();
        print('Token verification: ${savedToken != null}');
        if (savedToken != null) {
          print('Saved token length: ${savedToken.length}');
        }
      } else {
        print('ERROR: Tokens not found in login response!');
        print('Available keys in data: ${data.keys}');
      }

      if (!data.containsKey('user')) {
        print('ERROR: User data not found in login response!');
        print('Available keys in data: ${data.keys}');
        throw Exception('Invalid login response: missing user data');
      }

      final user = data['user'] as Map<String, dynamic>;

      // Validate role - only Customer and Guest can access mobile app
      final role = user['role'] as Map<String, dynamic>?;
      final roleName = role?['name']?.toString() ?? '';
      print('AuthService: User role is: $roleName');

      if (!_allowedMobileRoles.contains(roleName)) {
        // Clear tokens since this user shouldn't have access
        await _api.clearTokens();
        print('AuthService: Role "$roleName" not allowed on mobile app');
        throw Exception(
          'This account is for staff/admin access only. Please use the web portal to login.',
        );
      }

      return user;
    } catch (e) {
      print('AuthService: Login error: $e');
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
    await _api.clearTokens();
    await _storage.setGuestStatus(false); // Clear guest status on logout
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
      print('AuthService: Google login error: $e');
      rethrow;
    }
  }
}
