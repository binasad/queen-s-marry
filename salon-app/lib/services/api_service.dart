import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final StorageService _storage = const StorageService();
  late final Dio _dio;

  ApiService._internal() {
    final baseUrl = AppConfig.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 15,
        ), // Increased for network issues
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        validateStatus: (status) {
          return status != null && status < 500; // Don't throw on 4xx errors
        },
        // Disable caching to ensure fresh data
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );
    print('========================================');
    print('ApiService initialized');
    print('Base URL: $baseUrl');
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('Request timeout: 15 seconds');
    print('========================================');

    // Test connection on initialization
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      print('Testing backend connection...');
      final testDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl.replaceAll('/api/v1', ''),
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await testDio.get('/health');
      print('✅ Backend connection test: SUCCESS (${response.statusCode})');
    } catch (e) {
      print('❌ Backend connection test: FAILED');
      print('   Error: $e');
      print('   💡 Make sure backend is running and accessible');
      if (!kIsWeb) {
        print('   💡 For Android emulator: http://10.0.2.2:5000');
        print('   💡 For physical device: Use your computer\'s IP address');
      }
    }
  }

  bool _isRefreshing = false;
  Future<String?>? _refreshFuture;

  // Token helpers
  Future<String?> getAccessToken() => _storage.getAccessToken();
  Future<String?> getRefreshToken() => _storage.getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken) async =>
      _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  Future<void> clearTokens() => _storage.clearTokens();

  Dio get client => _dio;

  // Interceptor wiring
  void _ensureInterceptors() {
    // Clear existing interceptors to ensure we have the latest version
    // (important for hot reload)
    _dio.interceptors.clear();
    print('ApiService: Adding interceptors...');
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
    print(
      'ApiService: Interceptors added successfully (${_dio.interceptors.length} interceptors)',
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('===== ApiService Interceptor Called =====');
    print('Request: ${options.method} ${options.path}');

    final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;
    print('Requires auth: $requiresAuth');

    if (!requiresAuth) {
      print('No auth required, proceeding without token');
      return handler.next(options);
    }

    print('Retrieving access token...');
    final token = await getAccessToken();
    print('Token retrieved: ${token != null}');
    print('Token length: ${token?.length ?? 0}');

    if (token != null) {
      print(
        'Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
      );
      final authHeader = 'Bearer $token';
      options.headers['Authorization'] = authHeader;
      print('Authorization header set: ${authHeader.substring(0, 40)}...');
      print('Headers after setting: ${options.headers}');
    } else {
      print('ERROR: No token available for authenticated request!');
    }

    print('===== Interceptor Complete, Sending Request =====');
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');

    if (status == 401 && !isRefreshCall) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          final retryResponse = await _retryRequest(
            err.requestOptions,
            newToken,
          );
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await clearTokens();
      }
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    if (_isRefreshing) return _refreshFuture;

    _isRefreshing = true;
    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        completer.complete(null);
        return null;
      }

      final tokenDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      final response = await tokenDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccess = data['accessToken']?.toString();
        final newRefresh = data['refreshToken']?.toString() ?? refreshToken;

        if (newAccess != null) {
          await saveTokens(newAccess, newRefresh);
          completer.complete(newAccess);
          return newAccess;
        }
      }

      completer.complete(null);
      return null;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      completer.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final opts = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      extra: requestOptions.extra,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: opts,
    );
  }

  // Public HTTP helpers
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    _ensureInterceptors();
    final response = await _dio.get<Map<String, dynamic>>(
      endpoint,
      options: Options(
        extra: {'requiresAuth': requiresAuth},
        // Force fresh data - disable caching
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      _ensureInterceptors();
      final fullUrl = '${AppConfig.baseUrl}$endpoint';
      print('========================================');
      print('Making POST request');
      print('Full URL: $fullUrl');
      print('Endpoint: $endpoint');
      print('Request body: $body');
      print('========================================');

      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: body,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );

      print('========================================');
      print('Response received');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('========================================');

      return _handleResponse(response);
    } on DioException catch (e) {
      print('========================================');
      print('❌ DioException in POST request');
      print('  Endpoint: $endpoint');
      print('  Full URL: ${AppConfig.baseUrl}$endpoint');
      print('  Error type: ${e.type}');
      print('  Status code: ${e.response?.statusCode ?? "N/A"}');
      print('  Response data: ${e.response?.data ?? "N/A"}');
      print('  Error message: ${e.message}');

      // Provide helpful error messages
      if (e.type == DioExceptionType.connectionTimeout) {
        print('  💡 TROUBLESHOOTING:');
        print('     - Is the backend server running?');
        print('     - Check: http://localhost:5000/health');
        print(
          '     - For Android emulator, backend should be accessible at http://10.0.2.2:5000',
        );
        print('     - For physical device, use your computer\'s IP address');
      } else if (e.type == DioExceptionType.connectionError) {
        print('  💡 TROUBLESHOOTING:');
        print('     - Cannot connect to backend server');
        print('     - Verify backend is running on port 5000');
        print('     - Check firewall settings');
      }
      print('========================================');
      rethrow;
    } catch (e) {
      print('========================================');
      print('❌ Unexpected error in POST request: $e');
      print('========================================');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    _ensureInterceptors();
    final response = await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: body,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    _ensureInterceptors();
    final response = await _dio.delete<Map<String, dynamic>>(
      endpoint,
      data: data,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data;
    print('Handling response with status: ${response.statusCode}');

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      print('Response is successful');
      if (data is Map<String, dynamic>) {
        print('Returning response data as Map');
        return data;
      }
      print('Wrapping response data');
      return {'data': data};
    }

    print('Response indicates error');
    final message = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : 'Unknown error';
    final code = (data is Map && data['code'] != null)
        ? data['code'].toString()
        : null;
    print('Throwing ApiException with message: $message, code: $code');
    throw ApiException(
      statusCode: response.statusCode ?? 500,
      message: message,
      code: code,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException({required this.statusCode, required this.message, this.code});

  /// Check if this error is due to guest user restriction
  bool get isGuestRestricted => code == 'GUEST_RESTRICTED';

  @override
  String toString() => 'ApiException($statusCode): $message';
}
