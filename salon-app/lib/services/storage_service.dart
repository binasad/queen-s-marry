import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  const StorageService();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _isGuestKey = 'is_guest';
  static const _cachedProfileKey = 'cached_user_profile';

  FlutterSecureStorage get _secureStorage => const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_isGuestKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _isGuestKey);
    }
  }

  /// Save guest status
  Future<void> setGuestStatus(bool isGuest) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, isGuest);
    } else {
      await _secureStorage.write(key: _isGuestKey, value: isGuest.toString());
    }
  }

  /// Check if current user is a guest
  Future<bool> isGuest() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isGuestKey) ?? false;
    }
    final value = await _secureStorage.read(key: _isGuestKey);
    return value == 'true';
  }

  /// Cache user profile for instant app reopen (logged-in users)
  Future<void> saveCachedProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedProfileKey, jsonEncode(profile));
  }

  /// Get cached profile (instant, no network)
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cachedProfileKey);
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Clear cached profile (on logout)
  Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedProfileKey);
  }
}
