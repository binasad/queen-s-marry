import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.login(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Set user after Google, guest, or other token-based login
  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  /// Update user profile (e.g. after photo upload) - merges with existing user
  void updateUserProfile(Map<String, dynamic> updates) {
    if (_user == null) return;
    _user = {..._user!, ...updates};
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final hasTokens = await _authService.isLoggedIn();
    if (hasTokens && _user == null) {
      try {
        final profileData = await UserService().getProfile();
        final profileUser = profileData['user'] as Map<String, dynamic>?;
        if (profileUser != null) {
          _user = {
            ...profileUser,
            'role': profileUser['role'] ?? {'name': 'User'},
          };
        }
      } catch (_) {
        // Token may be expired
      }
    }
    notifyListeners();
  }
}
