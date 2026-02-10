import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getProfile() async {
    print('UserService: Calling GET /profile');

    // Check if token exists before request
    final token = await _api.getAccessToken();
    print('UserService: Token exists: ${token != null}');
    if (token != null) {
      print(
        'UserService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
    }

    final response = await _api.get('/profile');
    print('UserService: Profile response: $response');
    return response['data'] as Map<String, dynamic>;
  }

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
    return response['data'] as Map<String, dynamic>;
  }

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
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await _api.get('/users/$userId');
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteUser(String userId) async {
    await _api.delete('/users/$userId');
  }
}
