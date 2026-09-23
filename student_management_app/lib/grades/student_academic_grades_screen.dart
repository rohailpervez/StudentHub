import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/student.dart';
import '../services/student_api_service.dart';
import '../services/token_storage.dart';

class StudentAcademicGradesScreen extends StatefulWidget {
  const StudentAcademicGradesScreen({super.key});

  @override
  State<StudentAcademicGradesScreen> createState() =>
      _StudentAcademicGradesScreenState();
}

class _StudentAcademicGradesScreenState
    extends State<StudentAcademicGradesScreen> {
  static const String _baseUrl = 'http://localhost:5083';

  final StudentApiService _studentApiService = StudentApiService();
  final TokenStorage _tokenStorage = TokenStorage();

  Student? _student;

  List<Map<String, dynamic>> _grades = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedCourseName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD STUDENT + GRADES
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final student = await _studentApiService.getMyStudent();

      final token = await _tokenStorage.getToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/AcademicGrades/my'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load academic grades. '
              'Status code: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      final List<dynamic> data =
      decoded is List ? decoded : <dynamic>[];

      if (!mounted) return;

      setState(() {
        _student = student;
        _grades = data
            .whereType<Map<String, dynamic>>()
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // UNIQUE STUDENT SUBJECTS
  // ============================================================

  List<String> get _subjects {
    final subjects = <String>[];

    for (final subject in _student?.courses ?? <String>[]) {
      final name = subject.trim();

      if (name.isEmpty) continue;

      final alreadyExists = subjects.any(
            (item) => item.toLowerCase() == name.toLowerCase(),
      );

      if (!alreadyExists) {
        subjects.add(name);
      }
    }

    return subjects;
  }

  // ============================================================
  // FIND GRADE FOR SELECTED COURSE
  // ============================================================

  Map<String, dynamic>? _getGradeForCourse(String courseName) {
    for (final grade in _grades) {
      final gradeCourseName =
      (grade['courseName'] ?? '').toString().trim();

      if (gradeCourseName.toLowerCase() ==
          courseName.trim().toLowerCase()) {
        return grade;
      }
    }

    return null;
  }

  // ============================================================
  // GRADE VALUE
  // ============================================================

  String _formatGrade(dynamic value) {
    if (value == null) {
      return 'Not posted';
    }

    final number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(1);
  }

  // ============================================================
  // AVERAGE
  // ============================================================

  double? _calculateAverage(Map<String, dynamic> grade) {
    final midTerm = _toDouble(grade['midTermGrade']);
    final finalGrade = _toDouble(grade['finalGrade']);

    if (midTerm != null && finalGrade != null) {
      return (midTerm + finalGrade) / 2;
    }

    if (midTerm != null) {
      return midTerm;
    }

    if (finalGrade != null) {
      return finalGrade;
    }

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  String _performanceText(double? average) {
    if (average == null) {
      return 'Not available';
    }

    if (average >= 80) {
      return 'Excellent';
    }

    if (average >= 70) {
      return 'Very Good';
    }

    if (average >= 60) {
      return 'Good';
    }

    if (average >= 50) {
      return 'Needs Improvement';
    }

    return 'At Risk';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStudentInfo(),
            const SizedBox(height: 28),
            _buildCourseSection(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 25,
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
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View your academic performance by subject.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadData,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT INFO
  // ============================================================

  Widget _buildStudentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_student?.name ?? 'S').isNotEmpty
                    ? (_student?.name ?? 'S')[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _student?.name ?? 'Student',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _student?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_student?.id != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Student ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_student!.id}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // COURSE SECTION
  // ============================================================

  Widget _buildCourseSection() {
    final subjects = _subjects;

    if (subjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects found',
        message: 'Your enrolled subjects will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Subjects',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select a subject to view your grades.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // SUBJECTS
        ...subjects.map(
              (subject) {
            final isSelected =
                _selectedCourseName == subject;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseCard(subject),

                if (isSelected)
                  _buildGradeDetail(),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // COURSE CARD
  // ============================================================

  Widget _buildCourseCard(String courseName) {
    final grade = _getGradeForCourse(courseName);
    final hasGrade = grade != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedCourseName = courseName;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedCourseName == courseName
                  ? Colors.black
                  : Colors.grey.shade300,
              width: _selectedCourseName == courseName
                  ? 1.5
                  : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasGrade
                          ? 'Grades available'
                          : 'No grades posted yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasGrade
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRADE DETAIL
  // ============================================================

  Widget _buildGradeDetail() {
    if (_selectedCourseName == null) {
      return const SizedBox.shrink();
    }

    final grade = _getGradeForCourse(
      _selectedCourseName!,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: grade == null
          ? _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No grades posted',
        message:
        'Grades for $_selectedCourseName have not been posted yet.',
      )
          : _buildGradeCard(grade),
    );
  }

  // ============================================================
  // GRADE CARD
  // ============================================================

  Widget _buildGradeCard(Map<String, dynamic> grade) {
    final average = _calculateAverage(grade);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grade Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _performanceText(average),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedCourseName!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildGradeItem(
                  title: 'Mid-Term',
                  value: _formatGrade(
                    grade['midTermGrade'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradeItem(
                  title: 'Final',
                  value: _formatGrade(
                    grade['finalGrade'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradeItem(
                  title: 'Average',
                  value: average == null
                      ? '—'
                      : _formatGrade(average),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRADE ITEM
  // ============================================================

  Widget _buildGradeItem({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value == 'Not posted'
                ? value
                : '$value / 100',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.black,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load academic grades',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}