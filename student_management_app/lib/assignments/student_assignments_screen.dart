import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final int? initialAssignmentId;

  const StudentAssignmentsScreen({
    super.key,
    this.initialAssignmentId,
  });

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends State<StudentAssignmentsScreen> {
  static const String _baseUrl = 'http://localhost:5083';

  final TokenStorage _tokenStorage = TokenStorage();

  List<Map<String, dynamic>> _assignments = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _pendingAssignmentId;
  String _searchQuery = '';
  String _selectedSubject = 'All Subjects';
  String _selectedStatus = 'All Status';

  @override
  void initState() {
    super.initState();
    _pendingAssignmentId = widget.initialAssignmentId;
    _loadAssignments();
  }

  Future<String?> _getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<void> _loadAssignments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/StudentAssignments/my'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final assignments = decoded
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item as Map),
          )
              .toList();

          if (mounted) {
            setState(() {
              _assignments = assignments;
            });

            if (_pendingAssignmentId != null) {
              final assignmentId = _pendingAssignmentId;

              _pendingAssignmentId = null;

              final assignment = _assignments.firstWhere(
                    (item) => _toInt(item['id']) == assignmentId,
                orElse: () => <String, dynamic>{},
              );

              if (assignment.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  _showAssignmentDetails(assignment);
                });
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  _showSnackBar(
                    'Assignment not found.',
                    isError: true,
                  );
                });
              }
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _assignments = [];
            });
          }
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Your session has expired. Please login again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'You are not allowed to access student assignments.',
        );
      } else {
        throw Exception(
          'Failed to load assignments. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getAssignmentDetails(
      int assignmentId,
      ) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/StudentAssignments/my/$assignmentId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      if (response.statusCode == 401) {
        throw Exception('Your session has expired.');
      }

      if (response.statusCode == 404) {
        throw Exception('Assignment not found.');
      }

      throw Exception(
        'Failed to load assignment details. '
            'Status: ${response.statusCode}',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }

    return null;
  }

  Future<void> _viewAssignmentAttachment({
    required int assignmentId,
    required String fileName,
  }) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/StudentAssignments/my/$assignmentId/attachment',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to open assignment PDF. '
              'Status: ${response.statusCode}',
        );
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _AssignmentAttachmentPdfViewerScreen(
            title: fileName,
            pdfBytes: response.bodyBytes,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _showAssignmentDetails(
      Map<String, dynamic> assignment,
      ) async {
    final assignmentId = _toInt(assignment['id']);

    if (assignmentId == null) return;

    final details = await _getAssignmentDetails(assignmentId);

    if (!mounted || details == null) return;

    final title = _stringValue(
      details['title'] ?? assignment['title'],
    );

    final description = _stringValue(
      details['description'] ?? assignment['description'],
    );

    final courseName = _stringValue(
      details['courseName'] ?? assignment['courseName'],
    );

    final teacherName = _stringValue(
      details['createdByUserName'],
    );

    final dueDate = _parseDate(
      details['dueDate'] ?? assignment['dueDate'],
    );

    final createdAt = _parseDate(
      details['createdAt'] ?? assignment['createdAt'],
    );

    final isActive = details['isActive'] == true;
    final attachmentFileName = _stringValue(
      details['attachmentFileName'] ??
          details['fileName'] ??
          assignment['attachmentFileName'] ??
          assignment['fileName'],
    );
    final submission = details['submission'];

    final hasSubmission = submission is Map;

    final submissionData = hasSubmission
        ? Map<String, dynamic>.from(submission)
        : null;

    final submissionStatus = hasSubmission
        ? _stringValue(submissionData?['status'])
        : '';

    final grade = submissionData?['grade'];

    final isGraded =
        grade != null || submissionStatus.toLowerCase() == 'reviewed';

    final assignmentStatus = _getAssignmentStatus(
      assignment: details,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty
                                    ? 'Untitled Assignment'
                                    : title,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                courseName.isEmpty
                                    ? 'Subject not available'
                                    : courseName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _dialogStatusBadge(
                          assignmentStatus,
                          isGreen: assignmentStatus == 'Submitted' ||
                              assignmentStatus == 'Graded',
                          isRed: assignmentStatus == 'Overdue',
                        ),
                        const Spacer(),
                        if (isGraded && grade != null)
                          _gradeBadge(grade),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _detailRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Subject',
                      value: courseName.isEmpty
                          ? 'N/A'
                          : courseName,
                    ),

                    const SizedBox(height: 13),

                    _detailRow(
                      icon: Icons.person_outline,
                      label: 'Teacher',
                      value: teacherName.isEmpty
                          ? 'N/A'
                          : teacherName,
                    ),

                    const SizedBox(height: 13),

                    _detailRow(
                      icon: Icons.event_outlined,
                      label: 'Due date',
                      value: dueDate == null
                          ? 'N/A'
                          : _formatDateTime(dueDate),
                    ),

                    const SizedBox(height: 13),

                    _detailRow(
                      icon: Icons.add_circle_outline,
                      label: 'Created',
                      value: createdAt == null
                          ? 'N/A'
                          : _formatDateTime(createdAt),
                    ),

                    const SizedBox(height: 13),

                    _detailRow(
                      icon: Icons.circle_outlined,
                      label: 'Assignment',
                      value: isActive == true
                          ? 'Active'
                          : 'Inactive',
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE7E7E7),
                        ),
                      ),
                      child: Text(
                        description.isEmpty
                            ? 'No description provided.'
                            : description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),

                  if (attachmentFileName.isNotEmpty) ...[
                const SizedBox(height: 24),

              const Text(
                'Assignment Attachment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE7E7E7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        attachmentFileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    OutlinedButton.icon(
                      onPressed: () {
                        _viewAssignmentAttachment(
                          assignmentId: assignmentId,
                          fileName: attachmentFileName,
                        );
                      },
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: const Text('View PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ],
                    const SizedBox(height: 24),

                    const Text(
                      'Your Submission',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (submissionData != null)
                      _buildSubmissionCard(
                        submissionData,
                        detailed: true,
                      )
                    else
                      _buildNotSubmittedCard(),

                    const SizedBox(height: 24),

                    if (!hasSubmission && isActive == true)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showSubmitDialog(
                              assignmentId,
                              title,
                            );
                          },
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 19,
                          ),
                          label: const Text(
                            'Submit Assignment',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(
      Map<String, dynamic> submission, {
        bool detailed = false,
      }) {
    final fileName = _stringValue(
      submission['fileName'],
    );

    final filePath = _stringValue(
      submission['filePath'],
    );

    final status = _stringValue(
      submission['status'],
    );

    final feedback = _stringValue(
      submission['feedback'],
    );

    final grade = submission['grade'];

    final submittedAt = _parseDate(
      submission['submittedAt'],
    );

    final reviewed = status.toLowerCase() == 'reviewed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: reviewed
            ? const Color(0xFFF4FAF4)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: reviewed
              ? const Color(0xFFD8E8D8)
              : const Color(0xFFE4E4E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName.isEmpty
                      ? 'Submitted file'
                      : fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _smallStatusBadge(
                status.isEmpty ? 'Submitted' : status,
                isGreen: reviewed,
              ),
            ],
          ),

          if (filePath.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              filePath,
              maxLines: detailed ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],

          if (submittedAt != null) ...[
            const SizedBox(height: 12),
            _submissionInfoRow(
              Icons.access_time_outlined,
              'Submitted',
              _formatDateTime(submittedAt),
            ),
          ],

          if (grade != null) ...[
            const SizedBox(height: 10),
            _submissionInfoRow(
              Icons.grade_outlined,
              'Grade',
              '$grade / 100',
            ),
          ],

          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Feedback',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotSubmittedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.black54,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'You have not submitted this assignment yet.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submissionInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.black54,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSubmitDialog(
      int assignmentId,
      String assignmentTitle,
      ) async {
    PlatformFile? selectedFile;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Submit Assignment',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignmentTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assignment PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedFile == null
                                ? 'Select your assignment as a PDF file.'
                                : selectedFile!.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedFile == null
                                  ? Colors.black54
                                  : Colors.black,
                              fontWeight: selectedFile == null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'],
                                  withData: true,
                                );

                                if (result == null ||
                                    result.files.isEmpty) {
                                  return;
                                }

                                final file = result.files.first;

                                if (file.size > 10 * 1024 * 1024) {
                                  if (mounted) {
                                    _showSnackBar(
                                      'PDF file size cannot exceed 10 MB.',
                                      isError: true,
                                    );
                                  }
                                  return;
                                }

                                setDialogState(() {
                                  selectedFile = file;
                                });
                              },
                              icon: const Icon(
                                Icons.upload_file_outlined,
                                size: 20,
                              ),
                              label: Text(
                                selectedFile == null
                                    ? 'Choose PDF'
                                    : 'Change PDF',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(
                                  color: Colors.black,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                18,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedFile == null
                      ? null
                      : () {
                    Navigator.pop(dialogContext);

                    _submitAssignment(
                      assignmentId: assignmentId,
                      fileName: selectedFile!.name,
                      filePath: selectedFile!.path ?? '',
                      fileBytes: selectedFile!.bytes!,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black12,
                    disabledForegroundColor: Colors.black38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitAssignment({
    required int assignmentId,
    required String fileName,
    required String filePath,
    required List<int> fileBytes,
  }) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showSnackBar(
          'Authentication token not found.',
          isError: true,
        );
        return false;
      }

      if (filePath.isEmpty) {
        _showSnackBar(
          'Unable to access the selected PDF file.',
          isError: true,
        );
        return false;
      }

      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$_baseUrl/api/StudentAssignments/'
              'my/$assignmentId/upload',
        ),
      );

      uploadRequest.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      uploadRequest.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final uploadResponse = await uploadRequest.send();

      final uploadBody =
      await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200) {
        String message = 'PDF upload failed.';

        try {
          final decoded = jsonDecode(uploadBody);

          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded is String && decoded.isNotEmpty) {
            message = decoded;
          }
        } catch (_) {
          if (uploadBody.isNotEmpty) {
            message = uploadBody;
          }
        }

        _showSnackBar(
          message,
          isError: true,
        );

        return false;
      }

      final uploadDecoded = jsonDecode(uploadBody);

      if (uploadDecoded is! Map) {
        _showSnackBar(
          'Invalid response received from server.',
          isError: true,
        );
        return false;
      }

      final uploadedFileName =
          uploadDecoded['fileName']?.toString() ?? fileName;

      final uploadedFilePath =
          uploadDecoded['filePath']?.toString() ?? '';

      if (uploadedFilePath.isEmpty) {
        _showSnackBar(
          'PDF uploaded, but the server file path was not returned.',
          isError: true,
        );
        return false;
      }

      final submitResponse = await http.post(
        Uri.parse(
          '$_baseUrl/api/StudentAssignments/'
              'my/$assignmentId/submit',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fileName': uploadedFileName,
          'filePath': uploadedFilePath,
        }),
      );

      if (submitResponse.statusCode == 200 ||
          submitResponse.statusCode == 201) {
        _showSnackBar(
          'Assignment submitted successfully.',
        );

        await _loadAssignments();

        return true;
      }

      if (submitResponse.statusCode == 400) {
        String message = 'Unable to submit assignment.';

        try {
          final decoded = jsonDecode(submitResponse.body);

          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded is String && decoded.isNotEmpty) {
            message = decoded;
          }
        } catch (_) {}

        _showSnackBar(
          message,
          isError: true,
        );

        return false;
      }

      if (submitResponse.statusCode == 409) {
        _showSnackBar(
          'You have already submitted this assignment.',
          isError: true,
        );
        return false;
      }

      if (submitResponse.statusCode == 401) {
        _showSnackBar(
          'Your session has expired. Please login again.',
          isError: true,
        );
        return false;
      }

      _showSnackBar(
        'Submission failed. Status: ${submitResponse.statusCode}',
        isError: true,
      );

      return false;
    } catch (e) {
      _showSnackBar(
        'Unable to upload or submit the PDF: $e',
        isError: true,
      );

      return false;
    }
  }

  Widget _buildAssignmentCard(
      Map<String, dynamic> assignment,
      ) {
    final id = _toInt(assignment['id']);

    final title = _stringValue(
      assignment['title'],
    );

    final description = _stringValue(
      assignment['description'],
    );

    final courseName = _stringValue(
      assignment['courseName'],
    );

    final dueDate = _parseDate(
      assignment['dueDate'],
    );

    final isActive =
        assignment['isActive'] == true;

    final status = _getAssignmentStatus(
      assignment: assignment,
    );

    final submission =
    assignment['submission'];

    final hasSubmission = submission is Map;

    final grade = hasSubmission
        ? submission['grade']
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE6E6E6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty
                            ? 'Untitled Assignment'
                            : title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        courseName.isEmpty
                            ? 'Subject not available'
                            : courseName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view' &&
                        id != null) {
                      _showAssignmentDetails(
                        assignment,
                      );
                    }

                    if (value == 'submit' &&
                        id != null &&
                        !hasSubmission &&
                        isActive) {
                      _showSubmitDialog(
                        id,
                        title,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 19,
                          ),
                          SizedBox(width: 10),
                          Text('View Assignment'),
                        ],
                      ),
                    ),
                    if (!hasSubmission && isActive)
                      const PopupMenuItem(
                        value: 'submit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text('Submit Assignment'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _statusBadge(
                  status,
                  isOverdue: status == 'Overdue',
                  isSubmitted:
                  status == 'Submitted',
                  isGraded:
                  status == 'Graded',
                ),
                const Spacer(),
                if (grade != null)
                  _gradeBadge(grade),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              description.isEmpty
                  ? 'No description provided.'
                  : description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 17,
                    color: status == 'Overdue'
                        ? Colors.red.shade700
                        : Colors.black54,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      dueDate == null
                          ? 'Due date not available'
                          : 'Due ${_formatDateTime(dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                        color: status == 'Overdue'
                            ? Colors.red.shade700
                            : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (hasSubmission) ...[
              const SizedBox(height: 12),
              _buildMiniSubmissionSummary(
                Map<String, dynamic>.from(submission),
              ),
            ],

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: id == null
                        ? null
                        : () =>
                        _showAssignmentDetails(
                          assignment,
                        ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'View Details',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(
                        color: Color(0xFFD8D8D8),
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),

                if (!hasSubmission &&
                    isActive) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: id == null
                          ? null
                          : () =>
                          _showSubmitDialog(
                            id,
                            title,
                          ),
                      icon: const Icon(
                        Icons.upload_file_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Submit',
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.black,
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSubmissionSummary(
      Map<String, dynamic> submission,
      ) {
    final status = _stringValue(
      submission['status'],
    );

    final submittedAt = _parseDate(
      submission['submittedAt'],
    );

    final grade = submission['grade'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF5),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFDDE8DD),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Color(0xFF3F7043),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              grade != null
                  ? 'Submitted • Grade $grade/100'
                  : submittedAt != null
                  ? 'Submitted ${_formatDateTime(submittedAt)}'
                  : 'Submitted',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3F7043),
              ),
            ),
          ),
          if (status.isNotEmpty)
            Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3F7043),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(
      String text, {
        bool isOverdue = false,
        bool isSubmitted = false,
        bool isGraded = false,
      }) {
    Color background;
    Color foreground;

    if (isOverdue) {
      background = const Color(0xFFFFF0F0);
      foreground = Colors.red.shade700;
    } else if (isGraded) {
      background = const Color(0xFFEFF8EF);
      foreground = Colors.green.shade700;
    } else if (isSubmitted) {
      background = const Color(0xFFF0F7F0);
      foreground = Colors.green.shade700;
    } else if (text == 'Pending') {
      background = const Color(0xFFFFF8E8);
      foreground = const Color(0xFF8A6700);
    } else {
      background = const Color(0xFFF1F1F1);
      foreground = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  Widget _smallStatusBadge(
      String text, {
        bool isGreen = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isGreen
            ? const Color(0xFFEFF8EF)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isGreen
              ? Colors.green.shade700
              : Colors.black54,
        ),
      ),
    );
  }

  Widget _dialogStatusBadge(
      String text, {
        bool isGreen = false,
        bool isRed = false,
      }) {
    final Color background;
    final Color foreground;

    if (isRed) {
      background = const Color(0xFFFFF0F0);
      foreground = Colors.red.shade700;
    } else if (isGreen) {
      background = const Color(0xFFEFF8EF);
      foreground = Colors.green.shade700;
    } else {
      background = const Color(0xFFF2F2F2);
      foreground = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  Widget _gradeBadge(dynamic grade) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Grade $grade/100',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStats() {
    final total = _assignments.length;

    final active = _assignments.where(
          (assignment) =>
      assignment['isActive'] == true,
    ).length;

    final pending = _assignments.where(
          (assignment) =>
      _getAssignmentStatus(
        assignment: assignment,
      ) == 'Pending',
    ).length;

    final submitted = _assignments.where(
          (assignment) =>
      _getAssignmentStatus(
        assignment: assignment,
      ) == 'Submitted',
    ).length;

    final graded = _assignments.where(
          (assignment) =>
      _getAssignmentStatus(
        assignment: assignment,
      ) == 'Graded',
    ).length;

    final overdue = _assignments.where(
          (assignment) =>
      _getAssignmentStatus(
        assignment: assignment,
      ) == 'Overdue',
    ).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Total Assignments',
                value: total.toString(),
                icon: Icons.assignment_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Active',
                value: active.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Pending',
                value: pending.toString(),
                icon: Icons.schedule_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Submitted',
                value: submitted.toString(),
                icon: Icons.upload_file_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Graded',
                value: graded.toString(),
                icon: Icons.grade_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Overdue',
                value: overdue.toString(),
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
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

  Widget _buildFilters() {
    final subjects = <String>{
      'All Subjects',
      ..._assignments
          .map(
            (assignment) =>
            _stringValue(assignment['courseName']),
      )
          .where((subject) => subject.isNotEmpty),
    }.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText:
              'Search assignments, subjects or descriptions...',
              prefixIcon: const Icon(
                Icons.search_outlined,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final width =
              constraints.maxWidth >= 650
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      value: subjects.contains(
                        _selectedSubject,
                      )
                          ? _selectedSubject
                          : 'All Subjects',
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: const Icon(
                          Icons.menu_book_outlined,
                        ),
                        filled: true,
                        fillColor:
                        const Color(0xFFF7F7F7),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                      items: subjects
                          .map(
                            (subject) =>
                            DropdownMenuItem<String>(
                              value: subject,
                              child: Text(
                                subject,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: const Icon(
                          Icons.filter_list_outlined,
                        ),
                        filled: true,
                        fillColor:
                        const Color(0xFFF7F7F7),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Status',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Submitted',
                          child: Text('Submitted'),
                        ),
                        DropdownMenuItem(
                          value: 'Graded',
                          child: Text('Graded'),
                        ),
                        DropdownMenuItem(
                          value: 'Overdue',
                          child: Text('Overdue'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredAssignments() {
    return _assignments.where((assignment) {
      final title = _stringValue(
        assignment['title'],
      ).toLowerCase();

      final subject = _stringValue(
        assignment['courseName'],
      ).toLowerCase();

      final description = _stringValue(
        assignment['description'],
      ).toLowerCase();

      final status = _getAssignmentStatus(
        assignment: assignment,
      );

      final matchesSearch =
          _searchQuery.isEmpty ||
              title.contains(_searchQuery) ||
              subject.contains(_searchQuery) ||
              description.contains(_searchQuery);

      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
              _stringValue(
                assignment['courseName'],
              ) ==
                  _selectedSubject;

      final matchesStatus =
          _selectedStatus == 'All Status' ||
              status == _selectedStatus;

      return matchesSearch &&
          matchesSubject &&
          matchesStatus;
    }).toList();
  }

  String _getAssignmentStatus({
    required Map<String, dynamic> assignment,
  }) {
    final submission = assignment['submission'];

    if (submission is Map) {
      final status = _stringValue(
        submission['status'],
      ).toLowerCase();

      final grade = submission['grade'];

      if (grade != null ||
          status == 'reviewed' ||
          status == 'graded') {
        return 'Graded';
      }

      return 'Submitted';
    }

    final dueDate = _parseDate(
      assignment['dueDate'],
    );

    final isActive =
        assignment['isActive'] == true;

    if (isActive &&
        dueDate != null &&
        dueDate.isBefore(DateTime.now())) {
      return 'Overdue';
    }

    return 'Pending';
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.black54,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    String title = 'No Assignments Yet',
    String message =
    'Your teachers have not published any assignments for you yet.',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 34,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 38,
            color: Colors.black54,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to Load Assignments',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _errorMessage ??
                'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    if (parsed == null) return null;

    return parsed.toLocal();
  }

  String _formatDateTime(DateTime date) {
    final hour =
    date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
    date.minute.toString().padLeft(2, '0');

    final period =
    date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute $period';
  }

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade700 : Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssignments =
    _filteredAssignments();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: _loadAssignments,
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'My Assignments',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'View assignments, deadlines, submissions and teacher feedback.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                  Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _loadAssignments,
                          tooltip: 'Refresh',
                          icon: const Icon(
                            Icons.refresh_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    if (_isLoading)
                      const Padding(
                        padding:
                        EdgeInsets.symmetric(
                          vertical: 80,
                        ),
                        child: Center(
                          child:
                          CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorState()
                    else ...[
                        _buildStats(),

                        const SizedBox(height: 24),

                        _buildFilters(),

                        const SizedBox(height: 20),

                        if (_assignments.isEmpty)
                          _buildEmptyState()
                        else if (filteredAssignments.isEmpty)
                          _buildEmptyState(
                            title:
                            'No Matching Assignments',
                            message:
                            'Try changing your search or filters.',
                          )
                        else ...[
                            Row(
                              children: [
                                const Text(
                                  'Assignments',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${filteredAssignments.length} found',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                    Colors.black54,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Column(
                              children: filteredAssignments
                                  .map(
                                _buildAssignmentCard,
                              )
                                  .toList(),
                            ),
                          ],
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentAttachmentPdfViewerScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const _AssignmentAttachmentPdfViewerScreen({
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