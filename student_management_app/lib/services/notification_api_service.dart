import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class NotificationApiService {
  final String baseUrl =
      'http://localhost:5083/api/Notifications';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET NOTIFICATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid notifications response.');
    }

    return List<Map<String, dynamic>>.from(
      decoded.map(
            (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  // ============================================================
  // MARK ONE NOTIFICATION AS READ
  // ============================================================

  Future<void> markAsRead(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/read'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark notification as read.',
      );
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<void> markAllAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/read-all'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark all notifications as read.',
      );
    }
  }
}