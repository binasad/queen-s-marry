# Flutter App → Backend API Integration Guide

Complete guide for integrating your Flutter salon app with the Node.js backend API.

---

## 📋 Table of Contents

1. [Setup & Configuration](#setup--configuration)
2. [API Service Architecture](#api-service-architecture)
3. [Authentication Flow](#authentication-flow)
4. [All API Endpoints](#all-api-endpoints)
5. [Error Handling](#error-handling)
6. [Complete Code Examples](#complete-code-examples)

---

## 🔧 Setup & Configuration

### 1. Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1  # For state management
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 2. Environment Configuration

Create `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Development
  static const String devBaseUrl = 'http://localhost:5000/api/v1';
  
  // Production
  static const String prodBaseUrl = 'https://api.yoursalon.com/api/v1';
  
  // Current environment
  static const bool isProduction = false;
  
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
}
```

### 3. Android Network Configuration

**For development (localhost access):**

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

Add to `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

**Note:** Use `http://10.0.2.2:5000` for Android emulator (maps to host's localhost)

---

## 🏗️ API Service Architecture

### Base API Service (`lib/services/api_service.dart`)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.baseUrl;

  // Token management
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  // Get headers with authorization
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    
    if (includeAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Generic request handler
  Future<Map<String, dynamic>> handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Unknown error',
      );
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    final headers = await getHeaders(includeAuth: requiresAuth);
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return handleResponse(response);
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(includeAuth: requiresAuth);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return handleResponse(response);
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(includeAuth: requiresAuth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return handleResponse(response);
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

---

## 🔐 Authentication Flow

### Auth Service (`lib/services/auth_service.dart`)

```dart
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
    String? gender,
  }) async {
    final response = await _api.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (address != null) 'address': address,
        if (gender != null) 'gender': gender,
      },
      requiresAuth: false,
    );
    
    return response['data'];
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      {'email': email, 'password': password},
      requiresAuth: false,
    );
    
    final data = response['data'];
    await _api.saveTokens(
      data['accessToken'],
      data['refreshToken'],
    );
    
    return data['user'];
  }

  // Verify email
  Future<void> verifyEmail(String token) async {
    await _api.get('/auth/verify-email/$token', requiresAuth: false);
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      {'email': email},
      requiresAuth: false,
    );
  }

  // Reset password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      {'token': token, 'newPassword': newPassword},
      requiresAuth: false,
    );
  }

  // Change password (authenticated)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Logout
  Future<void> logout() async {
    await _api.clearTokens();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _api.getAccessToken();
    return token != null;
  }
}
```

---

## 📡 All API Endpoints

### User Service (`lib/services/user_service.dart`)

```dart
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  // Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get('/profile');
    return response['data'];
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? gender,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (gender != null) body['gender'] = gender;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    final response = await _api.put('/profile', body);
    return response['data'];
  }

  // Admin: List all users
  Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
  }) async {
    var endpoint = '/users?page=$page&limit=$limit';
    if (search != null) endpoint += '&search=$search';
    if (role != null) endpoint += '&role=$role';

    final response = await _api.get(endpoint);
    return response['data'];
  }

  // Admin: Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await _api.get('/users/$userId');
    return response['data'];
  }

  // Admin: Delete user
  Future<void> deleteUser(String userId) async {
    await _api.delete('/users/$userId');
  }
}
```

### Service Catalog Service (`lib/services/service_catalog_service.dart`)

```dart
import 'api_service.dart';

class ServiceCatalogService {
  final ApiService _api = ApiService();

  // Get all categories
  Future<List<dynamic>> getCategories() async {
    final response = await _api.get('/categories', requiresAuth: false);
    return response['data'];
  }

  // Get all services
  Future<Map<String, dynamic>> getServices({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    var endpoint = '/services?page=$page&limit=$limit';
    if (categoryId != null) endpoint += '&categoryId=$categoryId';
    if (minPrice != null) endpoint += '&minPrice=$minPrice';
    if (maxPrice != null) endpoint += '&maxPrice=$maxPrice';
    if (search != null) endpoint += '&search=$search';

    final response = await _api.get(endpoint, requiresAuth: false);
    return response['data'];
  }

  // Get service by ID
  Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    final response = await _api.get('/services/$serviceId', requiresAuth: false);
    return response['data'];
  }

  // Get all experts
  Future<List<dynamic>> getExperts({String? serviceId}) async {
    var endpoint = '/experts';
    if (serviceId != null) endpoint += '?serviceId=$serviceId';

    final response = await _api.get(endpoint, requiresAuth: false);
    return response['data'];
  }

  // Admin: Create service
  Future<Map<String, dynamic>> createService({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required int duration,
    String? imageUrl,
    List<String>? tags,
  }) async {
    final response = await _api.post('/services', {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (tags != null) 'tags': tags,
    });
    return response['data'];
  }

  // Admin: Update service
  Future<Map<String, dynamic>> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _api.put('/services/$serviceId', updates);
    return response['data'];
  }

  // Admin: Delete service
  Future<void> deleteService(String serviceId) async {
    await _api.delete('/services/$serviceId');
  }
}
```

### Appointment Service (`lib/services/appointment_service.dart`)

```dart
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  // Create appointment
  Future<Map<String, dynamic>> createAppointment({
    required String serviceId,
    required String appointmentDate,
    required String appointmentTime,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? expertId,
    String? notes,
    bool payNow = false,
    String? paymentMethod,
  }) async {
    final response = await _api.post('/appointments', {
      'serviceId': serviceId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      if (expertId != null) 'expertId': expertId,
      if (notes != null) 'notes': notes,
      'payNow': payNow,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    return response['data'];
  }

  // Get my appointments
  Future<List<dynamic>> getMyAppointments({String? status}) async {
    var endpoint = '/appointments/my';
    if (status != null) endpoint += '?status=$status';

    final response = await _api.get(endpoint);
    return response['data'];
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    await _api.delete('/appointments/$appointmentId/cancel?reason=$reason');
  }

  // Admin: Get all appointments
  Future<Map<String, dynamic>> getAllAppointments({
    int page = 1,
    int limit = 10,
    String? status,
    String? paymentStatus,
  }) async {
    var endpoint = '/appointments?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';
    if (paymentStatus != null) endpoint += '&paymentStatus=$paymentStatus';

    final response = await _api.get(endpoint);
    return response['data'];
  }

  // Admin: Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final response = await _api.put('/appointments/$appointmentId/status', {
      'status': status,
    });
    return response['data'];
  }

  // Admin: Mark appointment as paid
  Future<Map<String, dynamic>> markAsPaid(
    String appointmentId,
    String paymentMethod,
  ) async {
    final response = await _api.put('/appointments/$appointmentId/pay', {
      'paymentMethod': paymentMethod,
    });
    return response['data'];
  }

  // Admin: Dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/dashboard/stats');
    return response['data'];
  }
}
```

---

## 🎯 Complete Code Examples

### Example 1: Login Screen

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, ${user['name']}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Service List Screen

```dart
import 'package:flutter/material.dart';
import '../services/service_catalog_service.dart';

class ServiceListScreen extends StatefulWidget {
  @override
  _ServiceListScreenState createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _serviceService = ServiceCatalogService();
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final response = await _serviceService.getServices();
      setState(() {
        _services = response['services'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load services: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Services')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return ListTile(
                  leading: service['image_url'] != null
                      ? Image.network(service['image_url'], width: 50)
                      : Icon(Icons.cut),
                  title: Text(service['name']),
                  subtitle: Text('\$${service['price']} • ${service['duration']} min'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/service-details',
                      arguments: service['id'],
                    );
                  },
                );
              },
            ),
    );
  }
}
```

### Example 3: Book Appointment Screen

```dart
import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String serviceId;
  
  BookAppointmentScreen({required this.serviceId});

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _appointmentService = AppointmentService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _appointmentService.createAppointment(
        serviceId: widget.serviceId,
        appointmentDate: _selectedDate!.toIso8601String().split('T')[0],
        appointmentTime: '${_selectedTime!.hour}:${_selectedTime!.minute}:00',
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerEmail: _emailController.text,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 90)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Select Time'
                  : 'Time: ${_selectedTime!.format(context)}'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _bookAppointment,
                    child: Text('Book Appointment'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚨 Error Handling

### Global Error Handler

```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'You don\'t have permission to perform this action.';
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
    return 'An unexpected error occurred.';
  }

  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 🔄 State Management with Provider

### Auth Provider (`lib/providers/auth_provider.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

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

  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      // Fetch user profile
      // _user = await userService.getProfile();
      notifyListeners();
    }
  }
}
```

### Setup in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 📝 API Response Format

All responses follow this structure:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ ... ]
}
```

---

## 🔒 Security Best Practices

1. **Never log tokens** in production
2. **Clear tokens on logout**
3. **Validate all inputs** before sending
4. **Handle 401 errors** by redirecting to login
5. **Use HTTPS** in production
6. **Store tokens securely** using flutter_secure_storage
7. **Implement token refresh** when access token expires

---

## 📋 Quick Reference

### Base URL
- **Development:** `http://localhost:5000/api/v1` (or `http://10.0.2.2:5000/api/v1` for Android emulator)
- **Production:** `https://api.yoursalon.com/api/v1`

### Token Storage Keys
- `access_token` - JWT access token (7 days)
- `refresh_token` - JWT refresh token (30 days)

### Common Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (login required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `429` - Too Many Requests
- `500` - Server Error

---

## 🎯 Next Steps

1. ✅ Copy the service files to your Flutter project
2. ✅ Configure `AppConfig` with your backend URL
3. ✅ Test authentication flow first
4. ✅ Integrate service listing and booking
5. ✅ Add error handling and loading states
6. ✅ Implement state management (Provider/Riverpod/Bloc)
7. ✅ Test on both Android and iOS
8. ✅ Add token refresh mechanism
9. ✅ Implement offline support (optional)

---

**Last Updated:** January 21, 2026  
**Backend API Version:** v1  
**Compatible Flutter Version:** 3.0+
