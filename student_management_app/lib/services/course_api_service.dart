import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course.dart';
import 'token_storage.dart';

class CourseApiService {
  static const String baseUrl = 'http://localhost:5083/api/Courses';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token = await _tokenStorage.getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // GET - ALL COURSES
  // ============================================================

  Future<List<Course>> getCourses() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map(
            (json) => Course.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load courses. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // GET - COURSE BY ID
  // ============================================================

  Future<Course> getCourseById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Course.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load course. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // POST - ADD COURSE
  // ============================================================

  Future<Course> addCourse(Course course) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': course.name,
        'description': course.description,
        'durationMonths': course.durationMonths,
        'isActive': course.isActive,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Course.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to add course. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // PUT - UPDATE COURSE
  // ============================================================

  Future<Course> updateCourse(Course course) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${course.id}'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'id': course.id,
        'name': course.name,
        'description': course.description,
        'durationMonths': course.durationMonths,
        'isActive': course.isActive,
      }),
    );

    if (response.statusCode == 200) {
      return Course.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to update course. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // DELETE - DELETE COURSE
  // ============================================================

  Future<void> deleteCourse(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete course. Status code: ${response.statusCode}',
      );
    }
  }
}
