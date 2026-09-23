import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/attendance.dart';
import '../services/attendance_api_service.dart';
import 'edit_student_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student student;

  const StudentProfileScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState
    extends State<StudentProfileScreen> {
  final AttendanceApiService _attendanceApiService =
  AttendanceApiService();

  List<Attendance> _attendanceRecords = [];

  bool _isLoadingAttendance = true;
  String? _attendanceError;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final records =
      await _attendanceApiService.getAttendance();

      if (!mounted) return;

      setState(() {
        _attendanceRecords = records
            .where(
              (attendance) =>
          attendance.studentId == widget.student.id,
        )
            .toList();

        _attendanceRecords.sort(
              (a, b) => b.date.compareTo(a.date),
        );

        _isLoadingAttendance = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAttendance = false;
        _attendanceError = 'Unable to load attendance.';
      });
    }
  }

  int get _totalAttendance => _attendanceRecords.length;

  int get _presentCount => _attendanceRecords
      .where((attendance) => attendance.isPresent)
      .length;

  int get _absentCount => _attendanceRecords
      .where((attendance) => !attendance.isPresent)
      .length;

  double get _attendancePercentage {
    if (_totalAttendance == 0) {
      return 0;
    }

    return (_presentCount / _totalAttendance) * 100;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _editStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentScreen(
          student: widget.student,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(student),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAttendance,
              child: SingleChildScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(student),

                    const SizedBox(height: 24),

                    _buildBasicInformation(student),

                    const SizedBox(height: 24),

                    _buildAttendanceSection(),

                    const SizedBox(height: 24),

                    _buildRecentAttendance(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Student student) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),

          const SizedBox(width: 8),

          const Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Student Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'View student information and attendance',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          const Spacer(),

          OutlinedButton.icon(
            onPressed: _editStudent,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Student student) {
    final initial = student.name.isNotEmpty
        ? student.name.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
            const Color(0xFF111827),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  student.email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildStatusBadge(
                      student.isActive,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Student ID: #${student.id}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformation(Student student) {
    final courseNames = student.courses.isNotEmpty
        ? student.courses.join(', ')
        : student.course;

    final courseIds = student.courseIds.isNotEmpty
        ? student.courseIds.join(', ')
        : student.courseId?.toString() ?? '';

    return _buildSectionCard(
      title: 'Basic Information',
      icon: Icons.person_outline,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        childAspectRatio: 4,
        children: [
          _buildInfoItem(
            title: 'Full Name',
            value: student.name,
            icon: Icons.person_outline,
          ),

          _buildInfoItem(
            title: 'Email',
            value: student.email,
            icon: Icons.email_outlined,
          ),

          _buildInfoItem(
            title: 'Phone',
            value: student.phone,
            icon: Icons.phone_outlined,
          ),

          _buildInfoItem(
            title: 'Courses',
            value: courseNames.isEmpty
                ? 'Not assigned'
                : courseNames,
            icon: Icons.menu_book_outlined,
          ),

          _buildInfoItem(
            title: 'Course IDs',
            value: courseIds.isEmpty
                ? 'N/A'
                : courseIds,
            icon: Icons.tag_outlined,
          ),

          _buildInfoItem(
            title: 'Status',
            value: student.isActive
                ? 'Active'
                : 'Inactive',
            icon: student.isActive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    if (_isLoadingAttendance) {
      return _buildSectionCard(
        title: 'Attendance Summary',
        icon: Icons.fact_check_outlined,
        child: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_attendanceError != null) {
      return _buildSectionCard(
        title: 'Attendance Summary',
        icon: Icons.fact_check_outlined,
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              _attendanceError!,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return _buildSectionCard(
      title: 'Attendance Summary',
      icon: Icons.fact_check_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildAttendanceCard(
              title: 'Attendance',
              value:
              '${_attendancePercentage.toStringAsFixed(1)}%',
              subtitle: 'Overall percentage',
              icon: Icons.percent,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: _buildAttendanceCard(
              title: 'Present',
              value: _presentCount.toString(),
              subtitle: 'Days present',
              icon: Icons.check_circle_outline,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: _buildAttendanceCard(
              title: 'Absent',
              value: _absentCount.toString(),
              subtitle: 'Days absent',
              icon: Icons.cancel_outlined,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: _buildAttendanceCard(
              title: 'Total',
              value: _totalAttendance.toString(),
              subtitle: 'Recorded days',
              icon: Icons.calendar_month_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return _buildSectionCard(
      title: 'Recent Attendance',
      icon: Icons.history,
      child: _isLoadingAttendance
          ? const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      )
          : _attendanceRecords.isEmpty
          ? _buildNoAttendance()
          : Column(
        children: [
          ..._attendanceRecords
              .take(10)
              .map(_buildAttendanceRow),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(
      Attendance attendance,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 5,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: attendance.isPresent
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius:
              BorderRadius.circular(9),
            ),
            child: Icon(
              attendance.isPresent
                  ? Icons.check
                  : Icons.close,
              color: attendance.isPresent
                  ? const Color(0xFF166534)
                  : const Color(0xFFB91C1C),
              size: 20,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(attendance.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  attendance.courseName.isEmpty
                      ? 'Course not available'
                      : attendance.courseName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          _buildAttendanceBadge(
            attendance.isPresent,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBadge(
      bool isPresent,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isPresent
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isPresent ? 'Present' : 'Absent',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPresent
              ? const Color(0xFF166534)
              : const Color(0xFFB91C1C),
        ),
      ),
    );
  }

  Widget _buildNoAttendance() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 35,
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 45,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          const Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Attendance has not been recorded for this student yet.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 21,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
                size: 21,
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive
              ? const Color(0xFF166534)
              : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}