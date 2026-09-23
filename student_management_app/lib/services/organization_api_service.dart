import 'dart:convert';

import 'package:http/http.dart' as http;

class OrganizationApiService {
  static const String baseUrl = 'http://localhost:5083/api/Organizations';

  // ============================================================
  // GET ACTIVE ORGANIZATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getOrganizations() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<Map<String, dynamic>>.from(data);
    }

    throw Exception(
      'Failed to load organizations.',
    );
  }

  // ============================================================
  // CREATE ORGANIZATION
  // ============================================================

  Future<Map<String, dynamic>> createOrganization({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final data = jsonDecode(response.body);

    throw Exception(
      data is String ? data : 'Failed to create organization.',
    );
  }
}
