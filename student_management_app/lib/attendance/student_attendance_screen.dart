import 'package:flutter/material.dart';

import '../models/attendance_summary.dart';
import '../models/student.dart';
import '../services/attendance_api_service.dart';
import '../services/student_api_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final int? initialCourseId;

  const StudentAttendanceScreen({
    super.key,
    this.initialCourseId,
  });
  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends State<StudentAttendanceScreen> {
  final AttendanceApiService _attendanceApiService =
  AttendanceApiService();

  final StudentApiService _studentApiService =
  StudentApiService();

  Student? _student;
  AttendanceSummary? _summary;
  AttendanceSummary? _courseSummary;

  bool _isLoading = true;
  bool _isCourseLoading = false;

  String? _errorMessage;
  String? _courseErrorMessage;

  int? _selectedCourseId;
  String? _selectedCourseName;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  // ============================================================
  // LOAD STUDENT + OVERALL ATTENDANCE
  // ============================================================

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _studentApiService.getMyStudent(),
        _attendanceApiService.getMyAttendance(),
      ]);

      if (!mounted) return;

      setState(() {
        _student = results[0] as Student;
        _summary = results[1] as AttendanceSummary;
        _isLoading = false;
      });

      if (widget.initialCourseId != null &&
          _student != null) {
        final courseIndex =
        _student!.courseIds.indexOf(widget.initialCourseId!);

        if (courseIndex != -1 &&
            courseIndex < _student!.courses.length) {
          _loadCourseAttendance(
            courseId: widget.initialCourseId!,
            courseName: _student!.courses[courseIndex],
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD COURSE ATTENDANCE
  // ============================================================

  Future<void> _loadCourseAttendance({
    required int courseId,
    required String courseName,
  }) async {
    setState(() {
      _selectedCourseId = courseId;
      _selectedCourseName = courseName;
      _courseSummary = null;
      _courseErrorMessage = null;
      _isCourseLoading = true;
    });

    try {
      final summary =
      await _attendanceApiService.getMyCourseAttendance(
        courseId,
      );

      if (!mounted) return;

      setState(() {
        _courseSummary = summary;
        _isCourseLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _courseErrorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
        _isCourseLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
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

    if (_summary == null || _student == null) {
      return const Center(
        child: Text(
          'No attendance data available.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 15,
          ),
        ),
      );
    }

    return _buildAttendanceContent();
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildAttendanceContent() {
    final summary = _summary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 28),

          _buildOverviewCards(summary),

          const SizedBox(height: 28),

          _buildAttendancePercentage(summary),

          const SizedBox(height: 28),

          _buildSubjectsSection(),

          if (_selectedCourseId != null) ...[
            const SizedBox(height: 28),
            _buildCourseAttendanceSection(),
          ],

          const SizedBox(height: 28),

          _buildRecordsSection(summary),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your attendance and academic participation.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: IconButton(
            onPressed: _loadAttendance,
            tooltip: 'Refresh attendance',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OVERVIEW CARDS
  // ============================================================

  Widget _buildOverviewCards(
      AttendanceSummary summary,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return Column(
            children: [
              _buildStatCard(
                title: 'Total Classes',
                value: summary.totalClasses.toString(),
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 14),
              _buildStatCard(
                title: 'Present',
                value: summary.presentClasses.toString(),
                icon: Icons.check_circle_outline,
                isGreen: true,
              ),
              const SizedBox(height: 14),
              _buildStatCard(
                title: 'Absent',
                value: summary.absentClasses.toString(),
                icon: Icons.cancel_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Classes',
                value: summary.totalClasses.toString(),
                icon: Icons.calendar_month_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Present',
                value: summary.presentClasses.toString(),
                icon: Icons.check_circle_outline,
                isGreen: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Absent',
                value: summary.absentClasses.toString(),
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool isGreen = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isGreen
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGreen
                  ? const Color(0xFF18864B)
                  : Colors.black87,
              size: 23,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
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
  // OVERALL ATTENDANCE
  // ============================================================

  Widget _buildAttendancePercentage(
      AttendanceSummary summary,
      ) {
    final percentage = summary.attendancePercentage;
    final progress =
    (percentage / 100).clamp(0.0, 1.0);

    final bool isGood = percentage >= 75;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Attendance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your current attendance percentage',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: isGood
                      ? const Color(0xFF18864B)
                      : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE9E9E9),
              valueColor:
              AlwaysStoppedAnimation<Color>(
                isGood
                    ? const Color(0xFF18864B)
                    : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isGood
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 16,
                color: isGood
                    ? const Color(0xFF18864B)
                    : Colors.black54,
              ),
              const SizedBox(width: 7),
              Text(
                isGood
                    ? 'Attendance is in a good range.'
                    : 'Attendance needs improvement.',
                style: TextStyle(
                  fontSize: 13,
                  color: isGood
                      ? const Color(0xFF18864B)
                      : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MY SUBJECTS
  // ============================================================

  Widget _buildSubjectsSection() {
    final student = _student!;

    final courseIds = student.courseIds;
    final courses = student.courses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.black87,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select a subject to view its attendance.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${courses.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (courses.isEmpty)
            _buildEmptySubjects()
          else
            _buildSubjectsGrid(
              courseIds,
              courses,
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid(
      List<int> courseIds,
      List<String> courses,
      ) {
    final itemCount =
    courseIds.length < courses.length
        ? courseIds.length
        : courses.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 1;

        if (width >= 1100) {
          crossAxisCount = 3;
        } else if (width >= 700) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return Column(
            children: List.generate(
              itemCount,
                  (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == itemCount - 1
                      ? 0
                      : 12,
                ),
                child: _buildSubjectCard(
                  courseId: courseIds[index],
                  courseName: courses[index],
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            return _buildSubjectCard(
              courseId: courseIds[index],
              courseName: courses[index],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectCard({
    required int courseId,
    required String courseName,
  }) {
    final isSelected =
        _selectedCourseId == courseId;

    return InkWell(
      onTap: () {
        _loadCourseAttendance(
          courseId: courseId,
          courseName: courseName,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF1F8F4)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18864B)
                : Colors.black.withValues(
              alpha: 0.07,
            ),
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE1F3E8)
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.book_outlined,
                color: isSelected
                    ? const Color(0xFF18864B)
                    : Colors.black87,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                courseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF18864B)
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: isSelected ? 20 : 15,
              color: isSelected
                  ? const Color(0xFF18864B)
                  : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubjects() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: Colors.black26,
          ),
          SizedBox(height: 12),
          Text(
            'No subjects enrolled yet.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COURSE-WISE ATTENDANCE
  // ============================================================

  Widget _buildCourseAttendanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseHeader(),

          const SizedBox(height: 22),

          if (_isCourseLoading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 50,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            )
          else if (_courseErrorMessage != null)
            _buildCourseErrorState()
          else if (_courseSummary == null)
              _buildCourseEmptyState()
            else
              _buildCourseAttendanceContent(
                _courseSummary!,
              ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F7EF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Color(0xFF18864B),
            size: 22,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Subject Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedCourseName ??
                    'Selected subject',
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
          onPressed: () {
            if (_selectedCourseId == null ||
                _selectedCourseName == null) {
              return;
            }

            _loadCourseAttendance(
              courseId: _selectedCourseId!,
              courseName: _selectedCourseName!,
            );
          },
          tooltip: 'Refresh subject attendance',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseAttendanceContent(
      AttendanceSummary summary,
      ) {
    final percentage =
        summary.attendancePercentage;

    final progress =
    (percentage / 100).clamp(0.0, 1.0);

    final bool isGood = percentage >= 75;

    return Column(
      children: [
        _buildCourseStats(summary),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius:
            BorderRadius.circular(13),
            border: Border.all(
              color: Colors.black.withValues(
                alpha: 0.06,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subject Attendance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isGood
                          ? const Color(0xFF18864B)
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius:
                BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                  const Color(0xFFE5E5E5),
                  valueColor:
                  AlwaysStoppedAnimation<Color>(
                    isGood
                        ? const Color(0xFF18864B)
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildCourseRecords(summary),
      ],
    );
  }

  Widget _buildCourseStats(
      AttendanceSummary summary,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return Column(
            children: [
              _buildSmallCourseStat(
                'Total',
                summary.totalClasses.toString(),
                Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 10),
              _buildSmallCourseStat(
                'Present',
                summary.presentClasses.toString(),
                Icons.check_circle_outline,
                isGreen: true,
              ),
              const SizedBox(height: 10),
              _buildSmallCourseStat(
                'Absent',
                summary.absentClasses.toString(),
                Icons.cancel_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildSmallCourseStat(
                'Total',
                summary.totalClasses.toString(),
                Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCourseStat(
                'Present',
                summary.presentClasses.toString(),
                Icons.check_circle_outline,
                isGreen: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCourseStat(
                'Absent',
                summary.absentClasses.toString(),
                Icons.cancel_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallCourseStat(
      String title,
      String value,
      IconData icon, {
        bool isGreen = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: isGreen
                ? const Color(0xFF18864B)
                : Colors.black54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isGreen
                  ? const Color(0xFF18864B)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRecords(
      AttendanceSummary summary,
      ) {
    final records = summary.records;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Records',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          _buildCourseEmptyRecords()
        else
          Column(
            children: List.generate(
              records.length,
                  (index) {
                final record = records[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index == records.length - 1
                        ? 0
                        : 8,
                  ),
                  child:
                  _buildCourseRecord(record),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseRecord(
      AttendanceRecord record,
      ) {
    final date = record.date;

    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final isPresent = record.isPresent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFF0F0F0),
              borderRadius:
              BorderRadius.circular(9),
            ),
            child: Icon(
              isPresent
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: isPresent
                  ? const Color(0xFF18864B)
                  : Colors.black54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFF0F0F0),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPresent
                    ? const Color(0xFF18864B)
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseEmptyRecords() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 34,
            color: Colors.black26,
          ),
          SizedBox(height: 10),
          Text(
            'No attendance recorded for this subject yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Center(
        child: Text(
          'No attendance data available for this subject.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: Colors.black54,
          ),
          const SizedBox(height: 10),
          Text(
            _courseErrorMessage ??
                'Unable to load subject attendance.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              if (_selectedCourseId == null ||
                  _selectedCourseName == null) {
                return;
              }

              _loadCourseAttendance(
                courseId: _selectedCourseId!,
                courseName: _selectedCourseName!,
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OVERALL ATTENDANCE RECORDS
  // ============================================================

  Widget _buildRecordsSection(
      AttendanceSummary summary,
      ) {
    final records = summary.records;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'All Attendance Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${records.length} attendance record${records.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            if (records.isEmpty)
              _buildEmptyRecords()
            else
              _buildRecordsList(records),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecords() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 42,
            color: Colors.black26,
          ),
          SizedBox(height: 12),
          Text(
            'No attendance records yet.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(
      List<AttendanceRecord> records,
      ) {
    return Column(
      children: [
        ...List.generate(
          records.length,
              (index) {
            final record = records[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                index == records.length - 1
                    ? 0
                    : 10,
              ),
              child:
              _buildAttendanceRecord(record),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceRecord(
      AttendanceRecord record,
      ) {
    final date = record.date;

    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final isPresent = record.isPresent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFF1F1F1),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Icon(
              isPresent
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: isPresent
                  ? const Color(0xFF18864B)
                  : Colors.black54,
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
                  record.courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFF0F0F0),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPresent
                    ? const Color(0xFF18864B)
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          constraints:
          const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load attendance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ??
                    'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadAttendance,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}