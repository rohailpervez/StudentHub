import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class SuperAdminApiService {
  static const String _baseUrl = 'http://localhost:5083/api/SuperAdmin';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    return token;
  }

  // ============================================================
  // GET ALL ORGANIZATIONS
  // GET: /api/SuperAdmin/organizations
  // ============================================================

  Future<List<dynamic>> getOrganizations() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/organizations'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      'Failed to load organizations. '
      'Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // GET SINGLE ORGANIZATION
  // GET: /api/SuperAdmin/organizations/{id}
  // ============================================================

  Future<Map<String, dynamic>> getOrganization(int id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load organization details. '
      'Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // DELETE USER
  // DELETE: /api/SuperAdmin/users/{id}
  // ============================================================

  Future<void> deleteUser(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'This user cannot be deleted.',
      );
    }

    throw Exception(
      'Failed to delete user. '
      'Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // DELETE ORGANIZATION
  // DELETE: /api/SuperAdmin/organizations/{id}
  // ============================================================

  Future<void> deleteOrganization(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/organizations/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      'Failed to delete organization. '
      'Status code: ${response.statusCode}',
    );
  }
}
