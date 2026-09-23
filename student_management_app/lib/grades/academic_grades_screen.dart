import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/course.dart';
import '../services/student_api_service.dart';
import '../services/token_storage.dart';
import 'course_academic_grades_screen.dart';

class AcademicGradesScreen extends StatefulWidget {
  const AcademicGradesScreen({super.key});

  @override
  State<AcademicGradesScreen> createState() => _AcademicGradesScreenState();
}

class _AcademicGradesScreenState extends State<AcademicGradesScreen> {
  static const String _baseUrl = 'http://localhost:5083';

  final TokenStorage _tokenStorage = TokenStorage();
  final StudentApiService _studentApiService = StudentApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _grades = [];

  List<Student> _students = [];
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

// ============================================================
// INITIAL LOAD
// ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _studentApiService.getStudents(),
        _studentApiService.getCourses(),
        _loadAcademicGradesData(),
      ]);

      final students = results[0] as List<Student>;
      final courses = results[1] as List<Course>;

      if (!mounted) return;

      setState(() {
        _students = students;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
        'Something went wrong while loading academic grades.';
        _isLoading = false;
      });
    }
  }

// ============================================================
// LOAD ACADEMIC GRADES
// ============================================================

  Future<List<Map<String, dynamic>>> _loadAcademicGradesData() async {
    final token = await _tokenStorage.getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/AcademicGrades'),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final grades =
      data.map((item) => Map<String, dynamic>.from(item)).toList();

      if (mounted) {
        setState(() {
          _grades = grades;
        });
      }

      return grades;
    }

    throw Exception(
      'Unable to load academic grades. '
          'Status: ${response.statusCode}',
    );
  }

// ============================================================
// REFRESH ALL DATA
// ============================================================

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _studentApiService.getStudents(),
        _studentApiService.getCourses(),
        _loadAcademicGradesData(),
      ]);

      final students = results[0] as List<Student>;
      final courses = results[1] as List<Course>;

      if (!mounted) return;

      setState(() {
        _students = students;
        _courses = courses;
      });

      _showMessage(
        'Academic grades refreshed successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Refresh failed: ${_cleanError(e)}',
      );
    }
  }

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F6F6),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 22),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// HEADER
// ============================================================

  Widget _buildHeader() {
    final activeCourses =
        _courses.where((course) => course.isActive).length;

    final activeStudents =
        _students.where((student) => student.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Academic Grades',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Manage student academic performance by subject.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFD6D6D6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _showGradeForm,
              icon: const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label: const Text(
                'Add Grade',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            _buildSummaryCard(
              icon: Icons.menu_book_outlined,
              label: 'Active Courses',
              value: activeCourses.toString(),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              icon: Icons.people_outline_rounded,
              label: 'Active Students',
              value: activeStudents.toString(),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Grade Records',
              value: _grades.length.toString(),
            ),
          ],
        ),
      ],
    );
  }

// ============================================================
// SUMMARY CARD
// ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFE1E1E1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// CONTENT
// ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.black,
          ),
        ),
      );
    }

    if (_errorMessage != null && _courses.isEmpty) {
      return _buildErrorState();
    }

    if (_courses.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCoursesTable();
  }

// ============================================================
// ERROR
// ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1E1E1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load academic grades',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// EMPTY
// ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1E1E1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 38,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Courses Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No active courses have been added to this organization yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// COURSES TABLE
// ============================================================

  Widget _buildCoursesTable() {
    final activeCourses =
    _courses.where((course) => course.isActive).toList();

    if (activeCourses.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------
            // GRADEBOOK HEADER
            // ------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE7E7E7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Course Gradebook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activeCourses.length.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Select a course to manage grades',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // TABLE HEADER
            // ------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              color: const Color(0xFFF7F7F7),
              child: const Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SUBJECT / COURSE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    'ACTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // SCROLLABLE COURSE LIST
            // ------------------------------------------------------

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: activeCourses.length,
                itemBuilder: (context, index) {
                  final course = activeCourses[index];

                  return _buildCourseRow(
                    course: course,
                    index: index,
                    isLast: index == activeCourses.length - 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// COURSE ROW
// ============================================================

  Widget _buildCourseRow({
    required Course course,
    required int index,
    required bool isLast,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseAcademicGradesScreen(
                courseId: course.id,
                courseName: course.name,
                grades: _grades,
              ),
            ),
          );
        },
        hoverColor: const Color(0xFFF8F8F8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 72,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
              bottom: BorderSide(
                color: Color(0xFFEAEAEA),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        size: 19,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            course.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'View academic grade records',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ============================================================
// ADD GRADE FORM
// ============================================================

  void _showGradeForm() {
    int? selectedStudentId;
    int? selectedCourseId;

    final midTermController = TextEditingController();
    final finalController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            final studentCourses = _getCoursesForStudent(
              selectedStudentId,
            );

            if (selectedCourseId != null &&
                !studentCourses.any(
                      (course) => course.id == selectedCourseId,
                )) {
              selectedCourseId = null;
            }

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 720,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGradeDialogHeader(
                      onClose: () {
                        Navigator.pop(dialogContext);
                      },
                    ),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          26,
                          22,
                          26,
                          10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add an academic grade record for a student.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 22),

// ------------------------------------------------
// STUDENT
// ------------------------------------------------

                            _buildFieldLabel(
                              'Student',
                              required: true,
                            ),

                            const SizedBox(height: 7),

                            DropdownSearch<int>(
                              selectedItem: selectedStudentId,
                              itemAsString: (studentId) {
                                final student = _findStudent(studentId);

                                return student?.name ?? '';
                              },
                              items: (
                                  filter,
                                  infiniteScrollProps,
                                  ) {
                                final searchText =
                                filter.trim().toLowerCase();

                                return _activeStudents
                                    .where((student) {
                                  if (searchText.isEmpty) {
                                    return true;
                                  }

                                  return student.name
                                      .toLowerCase()
                                      .contains(searchText) ||
                                      student.email
                                          .toLowerCase()
                                          .contains(searchText);
                                })
                                    .map((student) => student.id)
                                    .toList();
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  hintText: 'Choose a student',
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 15,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(11),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD9D9D9),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(11),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD9D9D9),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(11),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search by name or email...',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(11),
                                    ),
                                  ),
                                ),
                                itemBuilder: (
                                    context,
                                    studentId,
                                    isDisabled,
                                    isSelected,
                                    ) {
                                  final student =
                                  _findStudent(studentId);

                                  return ListTile(
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3,
                                    ),
                                    leading: const CircleAvatar(
                                      radius: 19,
                                      backgroundColor:
                                      Color(0xFFF0F0F0),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 19,
                                        color: Colors.black,
                                      ),
                                    ),
                                    title: Text(
                                      student?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: student?.email != null
                                        ? Text(
                                      student!.email,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    )
                                        : null,
                                  );
                                },
                              ),
                              onChanged: (studentId) {
                                setDialogState(() {
                                  selectedStudentId = studentId;
                                  selectedCourseId = null;
                                });
                              },
                            ),

                            const SizedBox(height: 18),

// ------------------------------------------------
// COURSE
// ------------------------------------------------

                            _buildFieldLabel(
                              'Course',
                              required: true,
                            ),

                            const SizedBox(height: 7),

                            DropdownButtonFormField<int>(
                              value: selectedCourseId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: selectedStudentId == null
                                    ? 'Select student first'
                                    : studentCourses.isEmpty
                                    ? 'No courses assigned'
                                    : 'Choose a course',
                                prefixIcon: const Icon(
                                  Icons.menu_book_outlined,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(11),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9D9D9),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(11),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9D9D9),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(11),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              items: studentCourses.map(
                                    (course) {
                                  return DropdownMenuItem<int>(
                                    value: course.id,
                                    child: Text(
                                      course.name,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged:
                              selectedStudentId == null ||
                                  studentCourses.isEmpty
                                  ? null
                                  : (courseId) {
                                setDialogState(() {
                                  selectedCourseId =
                                      courseId;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

// ------------------------------------------------
// GRADE DETAILS HEADER
// ------------------------------------------------

                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Grade Details',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1F1),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '0 — 100',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 11),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildGradeInput(
                                    controller:
                                    midTermController,
                                    label: 'Mid-Term',
                                    hint: '0 - 100',
                                    icon:
                                    Icons.looks_one_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGradeInput(
                                    controller:
                                    finalController,
                                    label: 'Final',
                                    hint: '0 - 100',
                                    icon:
                                    Icons.looks_two_outlined,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

// ------------------------------------------------
// INFORMATION
// ------------------------------------------------

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius:
                                BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE4E4E4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(7),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE1E1E1),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Grades must be between 0 and 100. '
                                          'At least one grade is required.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        26,
                        14,
                        26,
                        22,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE8E8E8),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              final midTermText =
                              midTermController.text.trim();

                              final finalText =
                              finalController.text.trim();

                              final midTerm = midTermText.isEmpty
                                  ? null
                                  : double.tryParse(
                                midTermText,
                              );

                              final finalGrade = finalText.isEmpty
                                  ? null
                                  : double.tryParse(
                                finalText,
                              );

                              if (selectedStudentId == null) {
                                _showMessage(
                                  'Please select a student.',
                                );
                                return;
                              }

                              if (selectedCourseId == null) {
                                _showMessage(
                                  'Please select a course.',
                                );
                                return;
                              }

                              if (midTerm == null &&
                                  finalGrade == null) {
                                _showMessage(
                                  'At least one grade is required.',
                                );
                                return;
                              }

                              if (midTerm != null &&
                                  (midTerm < 0 || midTerm > 100)) {
                                _showMessage(
                                  'Mid-Term grade must be between 0 and 100.',
                                );
                                return;
                              }

                              if (finalGrade != null &&
                                  (finalGrade < 0 ||
                                      finalGrade > 100)) {
                                _showMessage(
                                  'Final grade must be between 0 and 100.',
                                );
                                return;
                              }

                              Navigator.pop(dialogContext);

                              await _createAcademicGrade(
                                studentId:
                                selectedStudentId!,
                                courseId: selectedCourseId!,
                                midTermGrade: midTerm,
                                finalGrade: finalGrade,
                              );

                              midTermController.dispose();
                              finalController.dispose();
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Save Grade',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// ============================================================
// GRADE DIALOG HEADER
// ============================================================

  Widget _buildGradeDialogHeader({
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        26,
        22,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE7E7E7),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 21,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Academic Grade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create a new grade record',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// FIELD LABEL
// ============================================================

  Widget _buildFieldLabel(
      String text, {
        bool required = false,
      }) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }

// ============================================================
// GRADE INPUT
// ============================================================

  Widget _buildGradeInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: Colors.black,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFD9D9D9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFD9D9D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Colors.black,
            width: 1.2,
          ),
        ),
      ),
    );
  }

// ============================================================
// ACTIVE STUDENTS
// ============================================================

  List<Student> get _activeStudents {
    return _students.where((student) => student.isActive).toList();
  }

// ============================================================
// FIND STUDENT
// ============================================================

  Student? _findStudent(int? studentId) {
    if (studentId == null) return null;

    try {
      return _students.firstWhere(
            (student) => student.id == studentId,
      );
    } catch (_) {
      return null;
    }
  }

// ============================================================
// COURSES FOR SELECTED STUDENT
// ============================================================

  List<Course> _getCoursesForStudent(
      int? studentId,
      ) {
    if (studentId == null) {
      return [];
    }

    final student = _findStudent(studentId);

    if (student == null) {
      return [];
    }

    return _courses.where((course) {
      return student.courseIds.contains(course.id) && course.isActive;
    }).toList();
  }

// ============================================================
// CREATE
// ============================================================

  Future<void> _createAcademicGrade({
    required int studentId,
    required int courseId,
    required double? midTermGrade,
    required double? finalGrade,
  }) async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/AcademicGrades'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentId': studentId,
          'courseId': courseId,
          'midTermGrade': midTermGrade,
          'finalGrade': finalGrade,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage(
          'Academic grade created successfully.',
        );

        await _loadAcademicGradesData();
      } else {
        _showMessage(
          _getApiErrorMessage(response),
        );
      }
    } catch (e) {
      _showMessage(
        'Unable to create academic grade.',
      );
    }
  }

// ============================================================
// API ERROR
// ============================================================

  String _getApiErrorMessage(
      http.Response response,
      ) {
    try {
      final data = jsonDecode(response.body);

      if (data is String) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          return data['message'].toString();
        }

        if (data['title'] != null) {
          return data['title'].toString();
        }

        if (data['errors'] != null) {
          return data['errors'].toString();
        }
      }
    } catch (_) {}

    return 'Request failed. Status: ${response.statusCode}';
  }

// ============================================================
// CLEAN ERROR
// ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

// ============================================================
// MESSAGE
// ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    super.dispose();
  }
}