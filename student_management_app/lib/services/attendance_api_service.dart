import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';
import 'token_storage.dart';
import '../models/attendance_summary.dart';

class AttendanceApiService {
  static const String baseUrl = 'http://localhost:5083/api/Attendance';

  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<List<Attendance>> getAttendance() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Attendance.fromJson(json))
          .toList();
    }

    throw Exception(
      'Failed to load attendance.',
    );
  }
  Future<List<Attendance>> getAttendanceByDate(
      DateTime date,
      ) async {
    final token = await _getToken();

    final dateString =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await http.get(
      Uri.parse('$baseUrl/date/$dateString'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Attendance.fromJson(json))
          .toList();
    }

    throw Exception(
      'Failed to load attendance for selected date.',
    );
  }
  Future<AttendanceSummary> getMyAttendance() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/my'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return AttendanceSummary.fromJson(
        data as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Failed to load your attendance. '
          'Status code: ${response.statusCode}',
    );
  }
  Future<AttendanceSummary> getMyCourseAttendance(
      int courseId,
      ) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/my/course/$courseId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return AttendanceSummary.fromJson(
        data as Map<String, dynamic>,
      );
    }

    String errorMessage =
        'Failed to load course attendance. '
        'Status code: ${response.statusCode}';

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);

        if (data is String && data.isNotEmpty) {
          errorMessage = data;
        } else if (data is Map<String, dynamic>) {
          errorMessage =
              data['message']?.toString() ??
                  data['title']?.toString() ??
                  data['detail']?.toString() ??
                  errorMessage;
        }
      } catch (_) {}
    }

    throw Exception(errorMessage);
  }
// MARK ATTENDANCE
// ============================================================

  Future<Map<String, dynamic>> markAttendance({
    required int studentId,
    required int courseId,
    required DateTime date,
    required bool isPresent,
  }) async {
    final token = await _getToken();

    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentId': studentId,
        'courseId': courseId,
        'date': '${dateString}T00:00:00',
        'isPresent': isPresent,
      }),
    );

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Attendance saved, but server returned no data.');
      }

      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        throw Exception('Invalid response received from server.');
      } catch (_) {
        throw Exception(
          'Attendance saved, but server returned an invalid response.',
        );
      }
    }

    // ----------------------------------------------------------
    // ERROR RESPONSE
    // ----------------------------------------------------------

    String errorMessage = 'Failed to mark attendance.';

    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          errorMessage =
              data['message']?.toString() ??
                  data['title']?.toString() ??
                  data['detail']?.toString() ??
                  errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
      } catch (_) {
        // Server returned plain text instead of JSON.
        errorMessage = response.body;
      }
    }

    throw Exception(errorMessage);
  }
  // ============================================================
  // UPDATE ATTENDANCE
  // ============================================================

  Future<Map<String, dynamic>> updateAttendance({
    required int id,
    required int studentId,
    required int courseId,
    required DateTime date,
    required bool isPresent,
  }) async {
    final token = await _getToken();

    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentId': studentId,
        'courseId': courseId,
        'date': '${dateString}T00:00:00',
        'isPresent': isPresent,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    throw Exception(
      data is Map<String, dynamic>
          ? data['message'] ?? data['title'] ?? 'Failed to update attendance.'
          : 'Failed to update attendance.',
    );
  }

  // ============================================================
  // DELETE ATTENDANCE
  // ============================================================

  Future<void> deleteAttendance(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      'Failed to delete attendance.',
    );
  }
}
