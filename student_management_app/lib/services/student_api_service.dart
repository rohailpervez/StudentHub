import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/student.dart';
import '../models/course.dart';
import 'token_storage.dart';

class StudentApiService {
  static const String baseUrl =
      'http://localhost:5083/api/Students';

  static const String coursesUrl =
      'http://localhost:5083/api/Courses';

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
  // GET ALL STUDENTS
  // ============================================================

  Future<List<Student>> getStudents() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map(
            (json) => Student.fromJson(
          json as Map<String, dynamic>,
        ),
      )
          .toList();
    }

    throw Exception(
      'Failed to load students. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // GET STUDENT BY ID
  // ============================================================

  Future<Student> getStudentById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load student. Status code: ${response.statusCode}',
    );
  }
// ============================================================
// GET LOGGED-IN STUDENT
// ============================================================

  Future<Student> getMyStudent() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load your student profile. Status code: ${response.statusCode}',
    );
  }

  Future<Student> updateMyStudentProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(
        jsonDecode(response.body),
      );
    }

    String errorMessage =
        'Failed to update profile. Status code: ${response.statusCode}';

    try {
      final data = jsonDecode(response.body);

      if (data is String && data.isNotEmpty) {
        errorMessage = data;
      } else if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data['title'] != null) {
          errorMessage = data['title'].toString();
        }
      }
    } catch (_) {
      // Keep default error message.
    }

    throw Exception(errorMessage);
  }

  // ============================================================
// UPLOAD MY PROFILE PICTURE
// ============================================================

  Future<Map<String, dynamic>> uploadMyProfilePicture(
      String filePath, {
        List<int>? fileBytes,
      }) async {
    final token = await _tokenStorage.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/me/profile-picture'),
    );

    request.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    String fileName =
        filePath.split('/').last.split('\\').last;

    // ------------------------------------------------------------
    // WEB FIX
    // If file picker does not provide an extension,
    // detect the image type from the actual file bytes.
    // ------------------------------------------------------------

    if (fileBytes != null) {
      final detectedExtension =
      _detectImageExtension(fileBytes);

      if (detectedExtension != null) {
        final hasExtension =
            fileName.contains('.') &&
                fileName.split('.').last.isNotEmpty;

        if (!hasExtension) {
          fileName = '$fileName$detectedExtension';
        }
      }
    }

    final mimeType = _getImageMimeType(fileName);


    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    } else {
      final file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(file);
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)
      as Map<String, dynamic>;
    }

    String errorMessage =
        'Failed to upload profile picture. '
        'Status code: ${response.statusCode}';

    try {
      final data = jsonDecode(response.body);

      if (data is String && data.isNotEmpty) {
        errorMessage = data;
      } else if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data['title'] != null) {
          errorMessage = data['title'].toString();
        }
      }
    } catch (_) {
      // Keep default error message.
    }

    throw Exception(errorMessage);
  }

// ============================================================
// DETECT IMAGE EXTENSION FROM BYTES
// ============================================================

  String? _detectImageExtension(List<int> bytes) {
    if (bytes.length >= 8) {
      // PNG
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A) {
        return '.png';
      }
    }

    if (bytes.length >= 3) {
      // JPG / JPEG
      if (bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return '.jpg';
      }
    }

    if (bytes.length >= 12) {
      // WEBP
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return '.webp';
      }
    }

    return null;
  }

// ============================================================
// IMAGE MIME TYPE
// ============================================================

  String _getImageMimeType(String filePath) {
    final extension = filePath
        .split('.')
        .last
        .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // ADD STUDENT
  // ============================================================

  Future<Student> addStudent(
      Student student, {
        required String password,
      }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': student.name,
        'email': student.email,
        'phone': student.phone,

        // Student login password
        'password': password,

        // Old compatibility
        'courseId': student.courseId,

        // New multiple courses
        'courseIds': student.courseIds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Student.fromJson(
        jsonDecode(response.body),
      );
    }

    String errorMessage =
        'Failed to add student. Status code: ${response.statusCode}';

    try {
      final data = jsonDecode(response.body);

      if (data is String && data.isNotEmpty) {
        errorMessage = data;
      } else if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data['title'] != null) {
          errorMessage = data['title'].toString();
        }
      }
    } catch (_) {
      // Keep default error message.
    }

    throw Exception(errorMessage);
  }

  // ============================================================
  // UPDATE STUDENT
  // ============================================================

  Future<Student> updateStudent(Student student) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${student.id}'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': student.name,
        'email': student.email,
        'phone': student.phone,

        // Old compatibility
        'courseId': student.courseId,

        // New multiple courses
        'courseIds': student.courseIds,
      }),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to update student. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // GET ALL COURSES
  // ============================================================

  Future<List<Course>> getCourses() async {
    final response = await http.get(
      Uri.parse(coursesUrl),
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
  // TOGGLE STUDENT ACTIVE / INACTIVE STATUS
  // ============================================================

  Future<bool> toggleStudentStatus(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/toggle-status'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['isActive'] == true;
    }

    throw Exception(
      'Failed to update student status. Status code: ${response.statusCode}',
    );
  }

  // ============================================================
  // DELETE STUDENT
  // ============================================================

  Future<void> deleteStudent(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to delete student. Status code: ${response.statusCode}',
      );
    }
  }
}