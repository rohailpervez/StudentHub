import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentsScreen extends StatefulWidget {
  final int? initialAssignmentId;

  const AssignmentsScreen({
    super.key,
    this.initialAssignmentId,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  static const String _baseUrl = 'http://localhost:5083';

  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _courses = [];
  bool _initialAssignmentOpened = false;

  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

// ============================================================
// AUTH
// ============================================================

  Future<String?> _getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

// ============================================================
// INITIAL DATA
// ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadAssignments(),
        _loadCourses(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (widget.initialAssignmentId != null &&
            !_initialAssignmentOpened) {
          _initialAssignmentOpened = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            Map<String, dynamic>? assignment;

            for (final item in _assignments) {
              if (_toInt(item['id']) == widget.initialAssignmentId) {
                assignment = item;
                break;
              }
            }

            if (assignment != null) {
              _showSubmissions(assignment);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _cleanError(e);
        });
      }
    }
  }

// ============================================================
// GET ASSIGNMENTS
// GET /api/Assignments
// ============================================================

  Future<void> _loadAssignments() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Assignments'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        _assignments = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _assignments = [];
      }

      return;
    }

    throw Exception(_getApiError(response));
  }

// ============================================================
// GET COURSES
// GET /api/Courses
// ============================================================

  Future<void> _loadCourses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Courses'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        _courses = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _courses = [];
      }

      return;
    }

    throw Exception(_getApiError(response));
  }

// ============================================================
// CREATE ASSIGNMENT
// POST /api/Assignments
// ============================================================

  Future<int> _createAssignment({
    required int courseId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Assignments'),
      headers: await _headers(),
      body: jsonEncode({
        'courseId': courseId,
        'title': title,
        'description': description,
        'dueDate': dueDate.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getApiError(response));
    }

    final responseData = jsonDecode(response.body);

    final assignmentId = responseData['id'];

    if (assignmentId == null) {
      throw Exception(
        'Assignment created, but assignment ID was not returned by the API.',
      );
    }

    await _loadAssignments();

    return assignmentId as int;
  }

// ============================================================
// UPDATE ASSIGNMENT
// PUT /api/Assignments/{id}
// ============================================================

  Future<void> _updateAssignment({
    required int id,
    required String title,
    required String description,
    required DateTime dueDate,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/Assignments/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'dueDate': dueDate.toUtc().toIso8601String(),
        'isActive': isActive,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_getApiError(response));
    }

    await _loadAssignments();
  }

  // ============================================================
// UPLOAD ASSIGNMENT ATTACHMENT PDF
// POST /api/Assignments/{id}/attachment
// ============================================================

  Future<void> _uploadAssignmentAttachment({
    required int assignmentId,
    required PlatformFile file,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Unable to read the selected PDF file.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$_baseUrl/api/Assignments/$assignmentId/attachment',
      ),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(_getApiError(response));
    }
  }
// ============================================================
// DELETE ASSIGNMENT
// DELETE /api/Assignments/{id}
// ============================================================

  Future<void> _deleteAssignment(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/Assignments/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getApiError(response));
    }

    await _loadAssignments();
  }

// ============================================================
// GET SUBMISSIONS
// GET /api/AssignmentSubmissions/assignment/{assignmentId}
// ============================================================

  Future<List<Map<String, dynamic>>> _getSubmissions(
    int assignmentId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/AssignmentSubmissions/assignment/$assignmentId',
      ),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(_getApiError(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

// ============================================================
// REVIEW SUBMISSION
// PUT /api/AssignmentSubmissions/{submissionId}/review
// ============================================================

  Future<void> _reviewSubmission({
    required int submissionId,
    required double grade,
    required String feedback,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/AssignmentSubmissions/$submissionId/review',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'grade': grade,
        'feedback': feedback,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_getApiError(response));
    }
  }

  // ============================================================
// VIEW SUBMISSION PDF
// GET /api/AssignmentSubmissions/{submissionId}/pdf
// ============================================================

  Future<void> _viewSubmissionPdf({
    required int submissionId,
    required String fileName,
  }) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showSnackBar(
          'Authentication token not found.',
          isError: true,
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/AssignmentSubmissions/$submissionId/pdf',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode != 200) {
        String message = 'Unable to open PDF.';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded is Map && decoded['title'] != null) {
            message = decoded['title'].toString();
          }
        } catch (_) {}

        _showSnackBar(
          '$message (${response.statusCode})',
          isError: true,
        );

        return;
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _SubmissionPdfViewerScreen(
            title: fileName,
            pdfBytes: response.bodyBytes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Unable to open PDF: $e',
        isError: true,
      );
    }
  }

// ============================================================
// CREATE / EDIT DIALOG
// ============================================================

  Future<void> _showAssignmentForm({
    Map<String, dynamic>? assignment,
  }) async {
    final bool isEditing = assignment != null;

    final titleController = TextEditingController(
      text: assignment?['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: assignment?['description']?.toString() ?? '',
    );

    int? selectedCourseId = _toInt(assignment?['courseId']);

    DateTime selectedDueDate = _parseDate(
      assignment?['dueDate'],
    );

    bool isActive = assignment?['isActive'] != false;

    PlatformFile? selectedAttachment;


    if (_courses.isEmpty) {
      await _loadCourses();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Assignment' : 'Create Assignment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogField(
                          controller: titleController,
                          label: 'Assignment Title',
                          hint: 'Enter assignment title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<int>(
                          value: _courseExists(selectedCourseId)
                              ? selectedCourseId
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Course',
                            hintText: 'Select course',
                            prefixIcon: const Icon(Icons.menu_book_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _courses.map((course) {
                            final id = _toInt(course['id']);

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                _courseName(course),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCourseId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a course';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildDialogField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Describe the assignment',
                          icon: Icons.description_outlined,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate.isBefore(
                                DateTime.now(),
                              )
                                  ? DateTime.now()
                                  : selectedDueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                selectedDueDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  23,
                                  59,
                                );
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              prefixIcon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _formatDate(selectedDueDate),
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedAttachment = result.files.first;

                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            selectedAttachment == null
                                ? 'Attach Assignment PDF'
                                : selectedAttachment!.name,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        if (isEditing) ...[
                          const SizedBox(height: 14),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Assignment Active',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Students can see active assignments.',
                            ),
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (selectedCourseId == null) {
                      return;
                    }

                    Navigator.pop(dialogContext);

                    await _runWithLoading(
                      isEditing
                          ? 'Updating assignment...'
                          : 'Creating assignment...',
                          () async {
                        if (isEditing) {
                          final assignmentId = _toInt(assignment['id']);

                          if (assignmentId == null) {
                            throw Exception('Assignment ID is missing.');
                          }

                          await _updateAssignment(
                            id: assignmentId,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            dueDate: selectedDueDate,
                            isActive: isActive,
                          );

                          if (selectedAttachment != null) {
                            await _uploadAssignmentAttachment(
                              assignmentId: assignmentId,
                              file: selectedAttachment!,
                            );
                          }
                        } else {
                          final assignmentId = await _createAssignment(
                            courseId: selectedCourseId!,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            dueDate: selectedDueDate,
                          );

                          if (selectedAttachment != null) {
                            await _uploadAssignmentAttachment(
                              assignmentId: assignmentId,
                              file: selectedAttachment!,
                            );
                          }
                        }
                      },
                    );

                    titleController.dispose();
                    descriptionController.dispose();
                  },
                  icon: Icon(
                    isEditing ? Icons.save_outlined : Icons.add,
                  ),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Create Assignment',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ============================================================
// SUBMISSIONS DIALOG
// ============================================================

  Future<void> _showSubmissions(
    Map<String, dynamic> assignment,
  ) async {
    final assignmentId = _toInt(assignment['id']);

    if (assignmentId == null) {
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: SizedBox(
            width: 850,
            height: 650,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getSubmissions(assignmentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildSubmissionError(
                    snapshot.error.toString(),
                  );
                }

                final submissions = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildSubmissionHeader(
                      assignment,
                      submissions.length,
                      dialogContext,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: submissions.isEmpty
                          ? _buildEmptySubmissions()
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: submissions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildSubmissionCard(
                                  submissions[index],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionHeader(
    Map<String, dynamic> assignment,
    int count,
    BuildContext dialogContext,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment['title']?.toString() ?? 'Assignment',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count submission${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    Map<String, dynamic> submission,
  ) {
    final status = submission['status']?.toString() ?? 'Submitted';

    final grade = submission['grade'];

    final isReviewed = grade != null || status.toLowerCase() == 'reviewed';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Colors.grey.shade100,
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission['studentName']?.toString() ??
                          'Unknown Student',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      submission['studentEmail']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                isReviewed ? 'Reviewed' : 'Submitted',
                isReviewed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    submission['fileName']?.toString() ?? 'Submitted file',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (submission['submittedAt'] != null)
                  Text(
                    _formatDateTime(
                      submission['submittedAt'],
                    ),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (grade != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.grade_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  'Grade: ${_formatGrade(grade)}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if ((submission['feedback']?.toString().trim().isNotEmpty ??
              false)) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Feedback: ${submission['feedback']}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final submissionId =
                    _toInt(submission['submissionId']);

                    final fileName =
                        submission['fileName']?.toString() ??
                            'Submitted Assignment.pdf';

                    if (submissionId == null) {
                      _showSnackBar(
                        'Submission information is invalid.',
                        isError: true,
                      );
                      return;
                    }

                    _viewSubmissionPdf(
                      submissionId: submissionId,
                      fileName: fileName,
                    );
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  ),
                  label: const Text('View PDF'),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    _showReviewDialog(submission);
                  },
                  icon: Icon(
                    isReviewed
                        ? Icons.edit_outlined
                        : Icons.rate_review_outlined,
                  ),
                  label: Text(
                    isReviewed ? 'Update Review' : 'Review',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// REVIEW DIALOG
// ============================================================

  Future<void> _showReviewDialog(
    Map<String, dynamic> submission,
  ) async {
    final gradeController = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );

    final feedbackController = TextEditingController(
      text: submission['feedback']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Review Submission',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    submission['studentName']?.toString() ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: gradeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Grade',
                      hintText: '0 - 100',
                      prefixIcon: const Icon(Icons.grade_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      final grade = double.tryParse(value ?? '');

                      if (grade == null) {
                        return 'Enter a valid grade';
                      }

                      if (grade < 0 || grade > 100) {
                        return 'Grade must be between 0 and 100';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Feedback',
                      hintText: 'Write feedback for the student',
                      prefixIcon: const Icon(Icons.comment_outlined),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final grade = double.parse(gradeController.text.trim());

                Navigator.pop(dialogContext);

                await _runWithLoading(
                  'Saving review...',
                  () async {
                    await _reviewSubmission(
                      submissionId: _toInt(submission['submissionId'])!,
                      grade: grade,
                      feedback: feedbackController.text.trim(),
                    );
                  },
                );

                if (mounted) {
                  _showSnackBar(
                    'Submission reviewed successfully.',
                  );

                  setState(() {});
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Review'),
            ),
          ],
        );
      },
    );

    gradeController.dispose();
    feedbackController.dispose();
  }

// ============================================================
// DELETE CONFIRMATION
// ============================================================

  Future<void> _confirmDelete(
    Map<String, dynamic> assignment,
  ) async {
    final id = _toInt(assignment['id']);

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Assignment',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${assignment['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runWithLoading(
      'Deleting assignment...',
      () async {
        await _deleteAssignment(id);
      },
    );
  }

// ============================================================
// MAIN UI
// ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredAssignments = _filteredAssignments;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildTopSection(),
                      const SizedBox(height: 20),
                      _buildStats(),
                      const SizedBox(height: 20),
                      _buildFilters(),
                      const SizedBox(height: 18),
                      Expanded(
                        child: filteredAssignments.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadInitialData,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    30,
                                  ),
                                  itemCount: filteredAssignments.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _buildAssignmentCard(
                                        filteredAssignments[index],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

// ============================================================
// TOP SECTION
// ============================================================

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assignments',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create, manage and review student assignments.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAssignmentForm(),
            icon: const Icon(Icons.add),
            label: const Text('Create Assignment'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

// ============================================================
// STATS
// ============================================================

  Widget _buildStats() {
    final total = _assignments.length;

    final active = _assignments
        .where(
          (assignment) => assignment['isActive'] == true,
        )
        .length;

    final inactive = total - active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.assignment_outlined,
              title: 'Total Assignments',
              value: total.toString(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _statCard(
              icon: Icons.check_circle_outline,
              title: 'Active',
              value: active.toString(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _statCard(
              icon: Icons.pause_circle_outline,
              title: 'Inactive',
              value: inactive.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// FILTERS
// ============================================================

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search assignments...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'Inactive',
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// ASSIGNMENT CARD
// ============================================================

  Widget _buildAssignmentCard(
    Map<String, dynamic> assignment,
  ) {
    final isActive = assignment['isActive'] == true;

    final dueDate = _parseDate(
      assignment['dueDate'],
    );

    final courseName = assignment['courseName']?.toString() ?? 'Unknown Course';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment['title']?.toString() ??
                            'Untitled Assignment',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _statusBadge(
                      isActive ? 'Active' : 'Inactive',
                      isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      courseName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Due ${_formatDate(dueDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if ((assignment['description']?.toString().trim().isNotEmpty ??
                    false)) ...[
                  const SizedBox(height: 10),
                  Text(
                    assignment['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 15),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'submissions') {
                _showSubmissions(assignment);
              } else if (value == 'edit') {
                _showAssignmentForm(
                  assignment: assignment,
                );
              } else if (value == 'delete') {
                _confirmDelete(assignment);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'submissions',
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text('View Submissions'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text('Edit Assignment'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Delete Assignment'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ============================================================
// STATUS BADGE
// ============================================================

  Widget _statusBadge(
    String text,
    bool positive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFEAF7EF) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: positive ? const Color(0xFF168342) : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

// ============================================================
// EMPTY STATES
// ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No assignments found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchQuery.isNotEmpty || _statusFilter != 'All'
                  ? 'Try changing your search or filter.'
                  : 'Create your first assignment to get started.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubmissions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No submissions yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Students have not submitted this assignment.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load submissions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _cleanError(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load assignments',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// HELPERS
// ============================================================

  List<Map<String, dynamic>> get _filteredAssignments {
    return _assignments.where((assignment) {
      final title = assignment['title']?.toString().toLowerCase() ?? '';

      final course = assignment['courseName']?.toString().toLowerCase() ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          course.contains(_searchQuery);

      final isActive = assignment['isActive'] == true;

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && isActive) ||
          (_statusFilter == 'Inactive' && !isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  bool _courseExists(int? id) {
    if (id == null) return false;

    return _courses.any(
      (course) => _toInt(course['id']) == id,
    );
  }

  String _courseName(Map<String, dynamic> course) {
    return course['name']?.toString() ??
        course['title']?.toString() ??
        'Course #${course['id']}';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    return parsed ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(dynamic value) {
    final date = _parseDate(value);

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_formatDate(date)} $hour:$minute $period';
  }

  String _formatGrade(dynamic value) {
    if (value == null) return '-';

    final number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(1);
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _runWithLoading(
    String message,
    Future<void> Function() action,
  ) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        );
      },
    );

    try {
      await action();

      if (mounted) {
        Navigator.of(context).pop();

        _showSnackBar(
          'Operation completed successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        _showSnackBar(
          _cleanError(e),
          isError: true,
        );
      }
    }
  }

  String _getApiError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }

        if (decoded['title'] != null) {
          return decoded['title'].toString();
        }

        if (decoded['errors'] is Map) {
          final errors = decoded['errors'] as Map;

          final messages = <String>[];

          for (final value in errors.values) {
            if (value is List) {
              messages.addAll(
                value.map((e) => e.toString()),
              );
            } else {
              messages.add(value.toString());
            }
          }

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }
    } catch (_) {}

    return 'Request failed with status ${response.statusCode}.';
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }
}

class _SubmissionPdfViewerScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const _SubmissionPdfViewerScreen({
    required this.title,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SfPdfViewer.memory(
        pdfBytes,
        enableDoubleTapZooming: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
