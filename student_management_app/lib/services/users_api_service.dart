import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class UsersApiService {
  static const String baseUrl = 'http://localhost:5083/api/Users';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET ALL USERS
  // GET: api/Users
  // ============================================================

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(data);
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to manage users.',
      );
    }

    throw Exception(
      'Failed to load users. (${response.statusCode})',
    );
  }

  // ============================================================
  // GET USER BY ID
  // GET: api/Users/{id}
  // ============================================================

  Future<Map<String, dynamic>> getUser(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to view this user.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('User not found.');
    }

    throw Exception(
      'Failed to load user. (${response.statusCode})',
    );
  }

  // ============================================================
  // UPDATE USER
  // PUT: api/Users/{id}
  // ============================================================

  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String fullName,
    required String email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to update users.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('User not found.');
    }

    throw Exception(
      data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to update user.',
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE USER
  // PATCH: api/Users/{id}/status
  // ============================================================

  Future<Map<String, dynamic>> updateUserStatus({
    required int id,
    required bool isActive,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status'),
      headers: await _headers(),
      body: jsonEncode({
        'isActive': isActive,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to change user status.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('User not found.');
    }

    throw Exception(
      data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to update user status.',
    );
  }

  // ============================================================
  // DELETE USER
  // DELETE: api/Users/{id}
  // ============================================================

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to delete users.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('User not found.');
    }

    throw Exception(
      'Failed to delete user. (${response.statusCode})',
    );
  }

  // CREATE TEACHER / STAFF
  // POST: api/Users/create-member
  // ============================================================

  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-member'),
      headers: await _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Unauthorized. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to create members.',
      );
    }

    throw Exception(
      data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to create member.',
    );
  }
}
