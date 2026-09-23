import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';

class CourseAcademicGradesScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>> grades;

  const CourseAcademicGradesScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.grades,
  });

  @override
  State<CourseAcademicGradesScreen> createState() =>
      _CourseAcademicGradesScreenState();
}

class _CourseAcademicGradesScreenState
    extends State<CourseAcademicGradesScreen> {
  static const String _baseUrl = 'http://localhost:5083';

  final TokenStorage _tokenStorage = TokenStorage();

  late List<Map<String, dynamic>> _courseGrades;

  bool _isLoading = false;


  @override
  void initState() {
    super.initState();

    _courseGrades = widget.grades.where((grade) {
      final gradeCourseId = int.tryParse(
        grade['courseId']?.toString() ?? '',
      );

      return gradeCourseId == widget.courseId;
    }).toList();
  }

// ================================================================
// LOAD COURSE GRADES
// ================================================================

  Future<void> _loadCourseGrades() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/AcademicGrades'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load academic grades. '
              'Status: ${response.statusCode}',
        );
      }

      final List<dynamic> data = jsonDecode(response.body);

      final grades = data
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .where((grade) {
        final gradeCourseId = int.tryParse(
          grade['courseId']?.toString() ?? '',
        );

        return gradeCourseId == widget.courseId;
      }).toList();

      if (!mounted) return;

      setState(() {
        _courseGrades = grades;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to refresh course grades.',
      );
    }
  }

// ================================================================
// UPDATE GRADE
// ================================================================


// ================================================================
// DELETE GRADE
// ================================================================

  Future<void> _deleteAcademicGrade(int gradeId) async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/api/AcademicGrades/$gradeId',
        ),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        String message = 'Unable to delete academic grade.';

        try {
          final responseData = jsonDecode(response.body);

          if (responseData is Map &&
              responseData['message'] != null) {
            message = responseData['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      await _loadCourseGrades();

      if (!mounted) return;

      _showMessage(
        'Academic grade deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

// ================================================================
// EDIT GRADE DIALOG
// ================================================================

  Future<void> _showEditGradeDialog(
      Map<String, dynamic> grade,
      ) async {
    final gradeId = int.tryParse(
      grade['id']?.toString() ?? '',
    );

    final studentId = int.tryParse(
      grade['studentId']?.toString() ?? '',
    );

    final courseId = int.tryParse(
      grade['courseId']?.toString() ?? '',
    );

    if (gradeId == null ||
        studentId == null ||
        courseId == null) {
      _showMessage(
        'Unable to edit this academic grade.',
      );
      return;
    }

    final midTermController = TextEditingController(
      text: _formatInputGrade(
        grade['midTermGrade'],
      ),
    );

    final finalController = TextEditingController(
      text: _formatInputGrade(
        grade['finalGrade'],
      ),
    );

    String? errorMessage;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            Future<void> saveGrade() async {
              final midTermText =
              midTermController.text.trim();

              final finalText =
              finalController.text.trim();

              final midTerm =
              double.tryParse(midTermText);

              final finalGrade =
              double.tryParse(finalText);

              if (midTermText.isEmpty &&
                  finalText.isEmpty) {
                setDialogState(() {
                  errorMessage =
                  'Enter at least one grade.';
                });
                return;
              }

              if (midTermText.isNotEmpty &&
                  midTerm == null) {
                setDialogState(() {
                  errorMessage =
                  'Enter a valid Mid-Term grade.';
                });
                return;
              }

              if (finalText.isNotEmpty &&
                  finalGrade == null) {
                setDialogState(() {
                  errorMessage =
                  'Enter a valid Final grade.';
                });
                return;
              }

              if (midTerm != null &&
                  (midTerm < 0 || midTerm > 100)) {
                setDialogState(() {
                  errorMessage =
                  'Mid-Term grade must be between 0 and 100.';
                });
                return;
              }

              if (finalGrade != null &&
                  (finalGrade < 0 || finalGrade > 100)) {
                setDialogState(() {
                  errorMessage =
                  'Final grade must be between 0 and 100.';
                });
                return;
              }

              setDialogState(() {
                errorMessage = null;
                isSaving = true;
              });

              try {
                final token =
                await _tokenStorage.getToken();

                final response = await http.put(
                  Uri.parse(
                    '$_baseUrl/api/AcademicGrades/$gradeId',
                  ),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    if (token != null && token.isNotEmpty)
                      'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'studentId': studentId,
                    'courseId': courseId,
                    'midTermGrade': midTerm,
                    'finalGrade': finalGrade,
                  }),
                );

                if (response.statusCode != 200) {
                  String message =
                      'Unable to update academic grade.';

                  try {
                    final responseData =
                    jsonDecode(response.body);

                    if (responseData is Map &&
                        responseData['message'] != null) {
                      message =
                          responseData['message'].toString();
                    }
                  } catch (_) {}

                  throw Exception(message);
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);

                await _loadCourseGrades();

                if (!mounted) return;

                _showMessage(
                  'Academic grade updated successfully.',
                );
              } catch (e) {
                if (!mounted) return;

                setDialogState(() {
                  isSaving = false;
                  errorMessage =
                      e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              titlePadding:
              const EdgeInsets.fromLTRB(
                26,
                26,
                26,
                10,
              ),
              contentPadding:
              const EdgeInsets.fromLTRB(
                26,
                12,
                26,
                8,
              ),
              actionsPadding:
              const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFF1F1F1),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 21,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Academic Grade',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Update student performance',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight:
                            FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildDialogSectionLabel(
                        'Student',
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFF7F7F7),
                          borderRadius:
                          BorderRadius.circular(11),
                          border: Border.all(
                            color:
                            const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildStudentAvatar(
                              grade['studentName']
                                  ?.toString() ??
                                  '',
                              size: 36,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                grade['studentName']
                                    ?.toString() ??
                                    'Unknown Student',
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 17),

                      _buildDialogSectionLabel(
                        'Course',
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFF7F7F7),
                          borderRadius:
                          BorderRadius.circular(11),
                          border: Border.all(
                            color:
                            const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                Colors.white,
                                borderRadius:
                                BorderRadius.circular(
                                  9,
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .menu_book_outlined,
                                size: 17,
                                color:
                                Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.courseName,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildGradeTextField(
                        controller:
                        midTermController,
                        label:
                        'Mid-Term Grade',
                        hint:
                        'Enter grade from 0 to 100',
                        icon:
                        Icons.looks_one_outlined,
                        enabled:
                        !isSaving,
                      ),

                      const SizedBox(height: 14),

                      _buildGradeTextField(
                        controller:
                        finalController,
                        label:
                        'Final Grade',
                        hint:
                        'Enter grade from 0 to 100',
                        icon:
                        Icons.looks_two_outlined,
                        enabled:
                        !isSaving,
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFF5F5F5),
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                            border: Border.all(
                              color:
                              const Color(0xFFD5D5D5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons
                                    .info_outline_rounded,
                                size: 17,
                                color:
                                Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style:
                                  const TextStyle(
                                    fontSize: 12,
                                    color:
                                    Colors.black87,
                                    fontWeight:
                                    FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : saveGrade,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.black,
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    midTermController.dispose();
    finalController.dispose();
  }

// ================================================================
// DIALOG SECTION LABEL
// ================================================================

  Widget _buildDialogSectionLabel(
      String text,
      ) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
    );
  }

// ================================================================
// GRADE TEXT FIELD
// ================================================================

  Widget _buildGradeTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 19,
          color: Colors.black54,
        ),
        filled: true,
        fillColor:
        const Color(0xFFFAFAFA),
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFDCDCDC),
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFDCDCDC),
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(11),
          borderSide:
          const BorderSide(
            color: Colors.black,
            width: 1.4,
          ),
        ),
      ),
    );
  }

// ================================================================
// DELETE CONFIRMATION
// ================================================================

  Future<void> _confirmDeleteGrade(
      Map<String, dynamic> grade,
      ) async {
    final gradeId = int.tryParse(
      grade['id']?.toString() ?? '',
    );

    if (gradeId == null) {
      _showMessage(
        'Unable to delete this academic grade.',
      );
      return;
    }

    final studentName =
        grade['studentName']?.toString() ??
            'this student';

    final shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          titlePadding:
          const EdgeInsets.fromLTRB(
            25,
            25,
            25,
            10,
          ),
          contentPadding:
          const EdgeInsets.fromLTRB(
            25,
            10,
            25,
            8,
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(
            19,
            8,
            19,
            19,
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFF1F1F1),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons
                      .delete_outline_rounded,
                  size: 21,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Grade?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        Colors.black54,
                        fontWeight:
                        FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            padding:
            const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF7F7F7),
              borderRadius:
              BorderRadius.circular(11),
              border: Border.all(
                color:
                const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(
              'Are you sure you want to delete the '
                  'academic grade for $studentName?',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              style:
              TextButton.styleFrom(
                foregroundColor:
                Colors.black,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.black,
                foregroundColor:
                Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteAcademicGrade(
      gradeId,
    );
  }

// ================================================================
// MESSAGE
// ================================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.black,
          behavior:
          SnackBarBehavior.floating,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(11),
          ),
          margin:
          const EdgeInsets.all(16),
        ),
      );
  }


// ================================================================
// BUILD
// ================================================================

  @override
  Widget build(BuildContext context) {
    final midTermAverage =
    _calculateAverage(
      _courseGrades,
      'midTermGrade',
    );

    final finalAverage =
    _calculateAverage(
      _courseGrades,
      'finalGrade',
    );

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding:
        const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildTopNavigation(context),

            const SizedBox(height: 20),

            _buildCourseHeader(
              courseGrades:
              _courseGrades,
              midTermAverage:
              midTermAverage,
              finalAverage:
              finalAverage,
            ),

            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _courseGrades.isEmpty
                  ? _buildEmptyState()
                  : _buildGradesTable(
                _courseGrades,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ================================================================
// TOP NAVIGATION
// ================================================================

  Widget _buildTopNavigation(
      BuildContext context,
      ) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(10),
          child: InkWell(
            borderRadius:
            BorderRadius.circular(10),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color:
                  const Color(0xFFDCDCDC),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Academic Grades',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.courseName,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

// ================================================================
// COURSE HEADER
// ================================================================

  Widget _buildCourseHeader({
    required List<Map<String, dynamic>>
    courseGrades,
    required double? midTermAverage,
    required double? finalAverage,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color:
              const Color(0xFFF0F0F0),
              borderRadius:
              BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 31,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'COURSE GRADEBOOK',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.7,
                    color:
                    Colors.grey.shade600,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.courseName,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'View and manage academic performance '
                      'for this course.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Row(
            children: [
              _buildSummaryCard(
                icon:
                Icons.people_outline_rounded,
                label: 'Students',
                value:
                '${courseGrades.length}',
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                icon:
                Icons.looks_one_outlined,
                label: 'Mid-Term',
                value:
                midTermAverage == null
                    ? '-'
                    : _formatAverage(
                  midTermAverage,
                ),
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                icon:
                Icons.looks_two_outlined,
                label: 'Final',
                value:
                finalAverage == null
                    ? '-'
                    : _formatAverage(
                  finalAverage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ================================================================
// SUMMARY CARD
// ================================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints:
      const BoxConstraints(
        minWidth: 105,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F7F7),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          const Color(0xFFE2E2E2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style:
                const TextStyle(
                  fontSize: 9,
                  color:
                  Colors.black54,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// ================================================================
// GRADES TABLE
// ================================================================

  Widget _buildGradesTable(
      List<Map<String, dynamic>>
      courseGrades,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              22,
              18,
              22,
              18,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(0xFFF0F0F0),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: const Icon(
                    Icons.grading_outlined,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'Student Grades',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Academic performance for this course',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                          Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(0xFFF2F2F2),
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    '${courseGrades.length} '
                        '${courseGrades.length == 1 ? 'Student' : 'Students'}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color:
            Color(0xFFE8E8E8),
          ),

    Expanded(
    child: SingleChildScrollView(
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
                    headingRowHeight: 56,
                    dataRowMinHeight: 70,
                    dataRowMaxHeight: 78,
                    columnSpacing: 34,
                    horizontalMargin: 22,
                    headingRowColor:
                    WidgetStateProperty.all(
                      const Color(0xFFF7F7F7),
                    ),
                    dividerThickness: 0.5,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Student',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Mid-Term',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Final',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Performance',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    rows: courseGrades
                        .map(
                          (grade) {
                        final studentName =
                            grade['studentName']
                                ?.toString() ??
                                '';

                        final studentEmail =
                            grade['studentEmail']
                                ?.toString() ??
                                '';

                        final midTerm =
                            grade['midTermGrade']
                                ?.toString() ??
                                '-';

                        final finalGrade =
                            grade['finalGrade']
                                ?.toString() ??
                                '-';

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Row(
                                  children: [
                                    _buildStudentAvatar(
                                      studentName,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child:
                                      Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            studentName
                                                .isEmpty
                                                ? 'Unknown Student'
                                                : studentName,
                                            style:
                                            const TextStyle(
                                              fontWeight:
                                              FontWeight
                                                  .w600,
                                              fontSize:
                                              13,
                                            ),
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                          ),
                                          if (studentEmail
                                              .isNotEmpty)
                                            const SizedBox(
                                              height:
                                              3,
                                            ),
                                          if (studentEmail
                                              .isNotEmpty)
                                            Text(
                                              studentEmail,
                                              style:
                                              const TextStyle(
                                                color:
                                                Colors.black54,
                                                fontSize:
                                                11,
                                              ),
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              _buildGradeBadge(
                                midTerm,
                              ),
                            ),
                            DataCell(
                              _buildGradeBadge(
                                finalGrade,
                              ),
                            ),
                            DataCell(
                              _buildPerformanceBadge(
                                midTerm,
                                finalGrade,
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize:
                                MainAxisSize
                                    .min,
                                children: [
                                  _buildActionButton(
                                    icon: Icons
                                        .edit_outlined,
                                    tooltip:
                                    'Edit',
                                    onTap: () {
                                      _showEditGradeDialog(
                                        grade,
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  _buildActionButton(
                                    icon: Icons
                                        .delete_outline_rounded,
                                    tooltip:
                                    'Delete',
                                    onTap: () {
                                      _confirmDeleteGrade(
                                        grade,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// ================================================================
// ACTION BUTTON
// ================================================================

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(8),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(8),
              border: Border.all(
                color:
                const Color(0xFFD8D8D8),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

// ================================================================
// STUDENT AVATAR
// ================================================================

  Widget _buildStudentAvatar(
      String name, {
        double size = 40,
      }) {
    String initial = '?';

    if (name.trim().isNotEmpty) {
      initial =
          name.trim()[0].toUpperCase();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
        const Color(0xFFEFEFEF),
        borderRadius:
        BorderRadius.circular(
          size * 0.28,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight:
          FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

// ================================================================
// GRADE BADGE
// ================================================================

  Widget _buildGradeBadge(
      String value,
      ) {
    final numericValue =
    double.tryParse(value);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF1F1F1),
        borderRadius:
        BorderRadius.circular(9),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: Text(
        numericValue == null
            ? value
            : _formatGrade(
          numericValue,
        ),
        style: const TextStyle(
          fontWeight:
          FontWeight.w700,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

// ================================================================
// PERFORMANCE BADGE
// ================================================================

  Widget _buildPerformanceBadge(
      String midTerm,
      String finalGrade,
      ) {
    final mid =
    double.tryParse(midTerm);

    final finalValue =
    double.tryParse(finalGrade);

    double? average;

    if (mid != null &&
        finalValue != null) {
      average =
          (mid + finalValue) / 2;
    } else if (mid != null) {
      average = mid;
    } else if (finalValue != null) {
      average = finalValue;
    }

    if (average == null) {
      return _buildSimpleBadge(
        'Pending',
        Icons.hourglass_empty_rounded,
      );
    }

    if (average >= 80) {
      return _buildSimpleBadge(
        'Excellent',
        Icons.star_outline_rounded,
      );
    }

    if (average >= 70) {
      return _buildSimpleBadge(
        'Good',
        Icons.thumb_up_outlined,
      );
    }

    if (average >= 50) {
      return _buildSimpleBadge(
        'Pass',
        Icons.check_circle_outline_rounded,
      );
    }

    return _buildSimpleBadge(
      'Needs Improvement',
      Icons.trending_down_rounded,
    );
  }

// ================================================================
// SIMPLE BADGE
// ================================================================

  Widget _buildSimpleBadge(
      String text,
      IconData icon,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF5F5F5),
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.black54,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// ================================================================
// LOADING STATE
// ================================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Loading grades...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ================================================================
// EMPTY STATE
// ================================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE0E0E0),
        ),
      ),
      child: Center(
        child: Container(
          constraints:
          const BoxConstraints(
            maxWidth: 500,
          ),
          padding:
          const EdgeInsets.all(38),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFF0F0F0),
                  borderRadius:
                  BorderRadius.circular(
                    22,
                  ),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 42,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Grades Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'No academic grades have been added '
                    'for ${widget.courseName} yet.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ================================================================
// CALCULATE AVERAGE
// ================================================================

  double? _calculateAverage(
      List<Map<String, dynamic>>
      courseGrades,
      String field,
      ) {
    final values = courseGrades
        .map(
          (grade) =>
          double.tryParse(
            grade[field]?.toString() ??
                '',
          ),
    )
        .whereType<double>()
        .toList();

    if (values.isEmpty) {
      return null;
    }

    final total = values.reduce(
          (value, element) =>
      value + element,
    );

    return total / values.length;
  }

// ================================================================
// FORMAT AVERAGE
// ================================================================

  String _formatAverage(
      double value,
      ) {
    if (value ==
        value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

// ================================================================
// FORMAT GRADE
// ================================================================

  String _formatGrade(
      double value,
      ) {
    if (value ==
        value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

// ================================================================
// FORMAT INPUT GRADE
// ================================================================

  String _formatInputGrade(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    final number =
    double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return '';
    }

    if (number ==
        number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toString();
  }
}