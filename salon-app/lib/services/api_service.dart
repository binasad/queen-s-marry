import 'dart:io';

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
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        contentType: Headers.jsonContentType,
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate',
        },
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

  /// Upload image file - returns { imageUrl: string }
  Future<String> uploadImage(File file, {String folder = 'profiles'}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'folder': folder,
    });
    final response = await _dio.post(
      '/upload-image',
      data: formData,
      options: Options(
        extra: {'requiresAuth': true},
        contentType: 'multipart/form-data',
      ),
    );
    final result = _handleResponse(response);
    final url = result['data']?['imageUrl'] ?? result['imageUrl'];
    if (url == null || url.toString().isEmpty) {
      throw ApiException(statusCode: 500, message: 'No image URL returned from upload.');
    }
    return url.toString();
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
    String message;
    if (data is String && data.isNotEmpty) {
      message = data; // express-rate-limit sends plain text
    } else if (data is Map) {
      message = data['message']?.toString() ?? data['error']?.toString() ?? 'Unknown error';
      // Use first validation error if available (e.g. "Customer phone is required")
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        final msg = first is Map ? first['msg']?.toString() : null;
        if (msg != null && msg.isNotEmpty) message = msg;
      }
    } else {
      message = 'Unknown error';
    }
    if (response.statusCode == 429) {
      message = 'Too many attempts. Please wait a few minutes and try again.';
    }
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
    final apiException = _dioExceptionToApiException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }

  ApiException _dioExceptionToApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          statusCode: 408,
          message: 'Request timed out. Please check your connection and try again.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          statusCode: 0,
          message: 'Connection failed. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final res = err.response;
        if (res != null) {
          final data = res.data;
          String message;
          if (data is String && data.isNotEmpty) {
            message = data;
          } else if (data is Map) {
            message = data['message']?.toString() ?? data['error']?.toString() ?? 'Unknown error';
          } else {
            message = 'Unknown error';
          }
          if (res.statusCode == 429) {
            message = 'Too many attempts. Please wait a few minutes and try again.';
          }
          final code = data is Map ? data['code']?.toString() : null;
          final isGuestRestricted = res.statusCode == 403 &&
              (code == 'GUEST_RESTRICTED' ||
                  message.toLowerCase().contains('guest') ||
                  message.toLowerCase().contains('sign up'));
          return ApiException(
            statusCode: res.statusCode ?? 500,
            message: message,
            isGuestRestricted: isGuestRestricted,
          );
        }
        return ApiException(statusCode: 500, message: 'Server error. Please try again later.');
      case DioExceptionType.cancel:
        return ApiException(statusCode: 0, message: 'Request was cancelled.');
      default:
        return ApiException(
          statusCode: 0,
          message: err.message ?? 'Connection failed. Please check your internet connection.',
        );
    }
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
