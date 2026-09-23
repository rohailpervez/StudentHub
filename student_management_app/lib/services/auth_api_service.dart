import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class AuthApiService {
  static const String baseUrl = 'http://localhost:5083/api/Auth';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];

      if (token != null && token.toString().isNotEmpty) {
        await _tokenStorage.saveToken(
          token.toString(),
        );
      }

      final user = data['user'];

      if (user != null) {
        await _tokenStorage.saveUser(
          jsonEncode(user),
        );
      }

      return data;
    }

    throw Exception(
      data is String ? data : data['message'] ?? 'Login failed.',
    );
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }

  // ============================================================
  // GET SAVED USER
  // ============================================================

  Future<Map<String, dynamic>?> getSavedUser() async {
    final userData = await _tokenStorage.getUser();

    if (userData == null || userData.isEmpty) {
      return null;
    }

    return jsonDecode(userData) as Map<String, dynamic>;
  }

  // ============================================================
  // CHECK JWT EXPIRY
  // ============================================================

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = parts[1];

      final normalizedPayload = base64Url.normalize(
        payload,
      );

      final payloadMap = jsonDecode(
        utf8.decode(
          base64Url.decode(normalizedPayload),
        ),
      ) as Map<String, dynamic>;

      final exp = payloadMap['exp'];

      if (exp == null) {
        return true;
      }

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        (exp as num).toInt() * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(expiryDate);
    } catch (_) {
      return true;
    }
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    if (_isTokenExpired(token)) {
      await logout();
      return false;
    }

    return true;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    await _tokenStorage.deleteUser();
  }

  // ============================================================
  // REGISTER USER IN EXISTING ORGANIZATION
  // ============================================================

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required int organizationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'organizationId': organizationId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data is String ? data : data['message'] ?? 'Registration failed.',
    );
  }

  // ============================================================
  // REGISTER NEW ORGANIZATION + FIRST ADMIN
  // ============================================================

  Future<Map<String, dynamic>> registerOrganization({
    required String organizationName,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register-organization'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'organizationName': organizationName,
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data is String
          ? data
          : data['message'] ?? 'Organization registration failed.',
    );
  }

  // ============================================================
// CHANGE PASSWORD
// ============================================================

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final token = await _tokenStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    throw Exception(
      data is String
          ? data
          : data['message'] ?? 'Failed to change password.',
    );
  }

}
