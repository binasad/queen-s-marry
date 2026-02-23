import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = const StorageService();
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
      if (_user != null) {
        Future(() => _storage.saveCachedProfile({'user': _user}));
      }
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
    if (user['isGuest'] != true) {
      Future(() => _storage.saveCachedProfile({'user': user}));
    }
    notifyListeners();
  }

  /// Update user profile (e.g. after photo upload or profile edit) - merges with existing user
  void updateUserProfile(Map<String, dynamic> updates) {
    if (_user == null) return;
    _user = {..._user!, ...updates};
    if (_user!['isGuest'] != true) {
      Future(() => _storage.saveCachedProfile({'user': _user}));
    }
    notifyListeners();
  }

  /// Fast check: restore guest or cached profile for instant app reopen
  Future<void> checkLoginStatus() async {
    // Load auth state in one parallel batch (faster than sequential)
    final results = await Future.wait([
      _authService.isGuestUser(),
      _authService.isLoggedIn(),
      _storage.getCachedProfile(),
    ]);
    final isGuest = results[0] as bool;
    final hasTokens = results[1] as bool;
    final cached = results[2] as Map<String, dynamic>?;

    // 1. Guest: instant, no API
    if (isGuest) {
      _user = {
        'id': 'guest_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Guest',
        'email': '',
        'profile_image_url': null,
        'isGuest': true,
        'role': {'name': 'Guest'},
      };
      notifyListeners();
      return;
    }

    // 2. Logged in: try cache first (instant)
    if (!hasTokens || _user != null) {
      notifyListeners();
      return;
    }
    if (cached != null) {
      final profileUser = cached['user'] as Map<String, dynamic>?;
      if (profileUser != null) {
        _user = {
          ...profileUser,
          'role': profileUser['role'] ?? {'name': 'User'},
        };
        notifyListeners();
        _refreshProfileInBackground();
        return;
      }
    }

    // 3. No cache: fetch (first-time only)
    try {
      final profileData = await UserService().getProfile();
      final profileUser = profileData['user'] as Map<String, dynamic>?;
      if (profileUser != null) {
        _user = {
          ...profileUser,
          'role': profileUser['role'] ?? {'name': 'User'},
        };
        await _storage.saveCachedProfile(profileData);
      }
    } catch (_) {}
    notifyListeners();
  }

  void _refreshProfileInBackground() {
    Future(() async {
      try {
        final profileData = await UserService().getProfile();
        final profileUser = profileData['user'] as Map<String, dynamic>?;
        if (profileUser != null) {
          _user = {
            ...profileUser,
            'role': profileUser['role'] ?? {'name': 'User'},
          };
          await _storage.saveCachedProfile(profileData);
          notifyListeners();
        }
      } catch (_) {}
    });
  }
}
