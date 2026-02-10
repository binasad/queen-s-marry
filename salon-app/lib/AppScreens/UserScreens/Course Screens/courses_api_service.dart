import 'dart:convert';
import 'package:http/http.dart' as http;

class CoursesApiService {
  final String baseUrl;
  CoursesApiService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> fetchCourses() async {
    final response = await http.get(Uri.parse('$baseUrl/courses'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true &&
          data['data'] != null &&
          data['data']['courses'] != null) {
        return List<Map<String, dynamic>>.from(data['data']['courses']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to load courses');
    }
  }
}
