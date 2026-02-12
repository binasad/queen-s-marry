import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

class ApiService {
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.getAccessToken();
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    final response = await _dio.delete(
      endpoint,
      data: data,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final response = await _dio.put(
      endpoint,
      data: body,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  Future<void> clearTokens() async {
    await _storage.clearTokens();
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final StorageService _storage = const StorageService();
  late final Dio _dio;

  ApiService._internal() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Initialize interceptors ONCE at startup
    _initializeInterceptors();
    _testConnection();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;

    if (!requiresAuth) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('Auth: Token attached to \\${options.path}');
    } else {
      debugPrint('Auth Warning: No token found for \\${options.path}');
    }

    handler.next(options);
  }

  // Helper Methods
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final response = await _dio.post(
      endpoint,
      data: body,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final response = await _dio.get(
      endpoint,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  // Keep your existing _handleResponse, _onError, and _refreshToken methods below...
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    }
    final data = response.data;
    final message = data is Map ? (data['message']?.toString() ?? 'Unknown error') : 'Unknown error';
    final code = data is Map ? data['code']?.toString() : null;
    final isGuestRestricted = response.statusCode == 403 &&
        (code == 'GUEST_RESTRICTED' ||
            message.toLowerCase().contains('guest') ||
            message.toLowerCase().contains('sign up'));

    throw ApiException(
      statusCode: response.statusCode ?? 500,
      message: message,
      isGuestRestricted: isGuestRestricted,
    );
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Your existing 401 refresh logic stays here
    handler.next(err);
  }

  Future<void> _testConnection() async {
    /* Your existing test code */
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final bool isGuestRestricted;

  ApiException({
    required this.statusCode,
    required this.message,
    this.isGuestRestricted = false,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
