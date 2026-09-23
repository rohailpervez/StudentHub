import 'package:flutter/material.dart';
import 'attendance_history_screen.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../services/student_api_service.dart';
import '../services/attendance_api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StudentApiService _studentApiService = StudentApiService();
  final AttendanceApiService _attendanceApiService = AttendanceApiService();

  DateTime selectedDate = DateTime.now();

  List<Student> _students = [];
  List<Course> _courses = [];

  int? _selectedCourseId;

  bool _isLoading = true;
  bool _isSaving = false;

  // ------------------------------------------------------------
  // ATTENDANCE DATA
  //
  // studentId -> attendance information
  //
  // {
  //   'id': attendanceId,
  //   'isPresent': true/false
  // }
  // ------------------------------------------------------------

  final Map<int, Map<String, dynamic>> _attendanceRecords = {};

  // ------------------------------------------------------------
  // INITIAL LOAD
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ------------------------------------------------------------
  // LOAD COURSES + STUDENTS
  // ------------------------------------------------------------

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _studentApiService.getStudents(),
        _studentApiService.getCourses(),
      ]);

      final students = results[0] as List<Student>;
      final courses = results[1] as List<Course>;

      if (!mounted) return;

      setState(() {
        _students = students;
        _courses = courses;
        _isLoading = false;
      });

      await _loadAttendanceForDate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceForDate() async {
    try {
      final records =
      await _attendanceApiService.getAttendanceByDate(selectedDate);

      final Map<int, Map<String, dynamic>> newRecords = {};

      for (final item in records) {
        if (_selectedCourseId == null) {
          continue;
        }

        if (item.courseId != _selectedCourseId) {
          continue;
        }

        final studentId = item.studentId;

        newRecords[studentId] = {
          'id': item.id,
          'isPresent': item.isPresent,
        };
      }

      if (!mounted) return;

      setState(() {
        _attendanceRecords
          ..clear()
          ..addAll(newRecords);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load attendance: ${_cleanError(e)}',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SELECT DATE
  // ------------------------------------------------------------

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select attendance date',
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
      _attendanceRecords.clear();
    });

    await _loadAttendanceForDate();
  }

  // ------------------------------------------------------------
  // COURSE CHANGE
  // ------------------------------------------------------------

  Future<void> _onCourseChanged(int? courseId) async {
    setState(() {
      _selectedCourseId = courseId;
      _attendanceRecords.clear();
    });

    if (courseId != null) {
      await _loadAttendanceForDate();
    }
  }

  // ------------------------------------------------------------
  // FILTER STUDENTS BY COURSE
  // ------------------------------------------------------------

  List<Student> get _courseStudents {
    if (_selectedCourseId == null) {
      return [];
    }

    return _students.where((student) {
      return student.courseIds.contains(_selectedCourseId) &&
          student.isActive;
    }).toList();
  }

  // ------------------------------------------------------------
  // SELECTED COURSE
  // ------------------------------------------------------------

  Course? get _selectedCourse {
    if (_selectedCourseId == null) return null;

    try {
      return _courses.firstWhere(
        (course) => course.id == _selectedCourseId,
      );
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // MARK STUDENT PRESENT / ABSENT LOCALLY
  // ------------------------------------------------------------

  void _setAttendance(
    int studentId,
    bool isPresent,
  ) {
    setState(() {
      final existing = _attendanceRecords[studentId];

      _attendanceRecords[studentId] = {
        'id': existing?['id'],
        'isPresent': isPresent,
      };
    });
  }

  // ------------------------------------------------------------
  // MARK ALL PRESENT
  // ------------------------------------------------------------

  void _markAllPresent() {
    final students = _courseStudents;

    if (students.isEmpty) return;

    setState(() {
      for (final student in students) {
        final existing = _attendanceRecords[student.id];

        _attendanceRecords[student.id] = {
          'id': existing?['id'],
          'isPresent': true,
        };
      }
    });
  }

  // ------------------------------------------------------------
  // MARK ALL ABSENT
  // ------------------------------------------------------------

  void _markAllAbsent() {
    final students = _courseStudents;

    if (students.isEmpty) return;

    setState(() {
      for (final student in students) {
        final existing = _attendanceRecords[student.id];

        _attendanceRecords[student.id] = {
          'id': existing?['id'],
          'isPresent': false,
        };
      }
    });
  }

  // ------------------------------------------------------------
  // SAVE ATTENDANCE
  // ------------------------------------------------------------

  Future<void> _saveAttendance() async {
    final students = _courseStudents;

    if (_selectedCourseId == null) {
      _showMessage('Please select a course first.');
      return;
    }

    if (students.isEmpty) {
      _showMessage(
        'There are no active students in this course.',
      );
      return;
    }

    // Check that every student has a status
    final incompleteStudents = students.where((student) {
      return !_attendanceRecords.containsKey(student.id);
    }).toList();

    if (incompleteStudents.isNotEmpty) {
      _showMessage(
        'Please mark attendance for all students first.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      int created = 0;
      int updated = 0;

      for (final student in students) {
        final record = _attendanceRecords[student.id]!;

        final attendanceId = record['id'];
        final isPresent = record['isPresent'] == true;

        if (attendanceId is int && attendanceId > 0) {
          await _attendanceApiService.updateAttendance(
            id: attendanceId,
            studentId: student.id,
            courseId: _selectedCourseId!,
            date: selectedDate,
            isPresent: isPresent,
          );

          updated++;
        } else {
          await _attendanceApiService.markAttendance(
            studentId: student.id,
            courseId: _selectedCourseId!,
            date: selectedDate,
            isPresent: isPresent,
          );

          created++;
        }
      }

      await _loadAttendanceForDate();

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Attendance saved successfully. '
        '$created added, $updated updated.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save attendance: ${_cleanError(e)}',
      );
    }
  }

  // ------------------------------------------------------------
  // DELETE ATTENDANCE
  // ------------------------------------------------------------

  Future<void> _deleteAttendance(Student student) async {
    final record = _attendanceRecords[student.id];

    final attendanceId = record?['id'];

    if (attendanceId is! int || attendanceId <= 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Attendance?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete attendance for '
            '${student.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
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

    try {
      await _attendanceApiService.deleteAttendance(
        attendanceId,
      );

      if (!mounted) return;

      setState(() {
        _attendanceRecords.remove(student.id);
      });

      _showMessage(
        'Attendance deleted for ${student.name}.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete attendance: ${_cleanError(e)}',
      );
    }
  }

  // ------------------------------------------------------------
  // REFRESH
  // ------------------------------------------------------------

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _studentApiService.getStudents(),
        _studentApiService.getCourses(),
      ]);

      final students = results[0] as List<Student>;
      final courses = results[1] as List<Course>;

      if (!mounted) return;

      setState(() {
        _students = students;
        _courses = courses;
      });

      await _loadAttendanceForDate();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Refresh failed: ${_cleanError(e)}',
      );
    }
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  int get _presentCount {
    return _courseStudents.where((student) {
      return _attendanceRecords[student.id]?['isPresent'] == true;
    }).length;
  }

  int get _absentCount {
    return _courseStudents.where((student) {
      return _attendanceRecords[student.id]?['isPresent'] == false;
    }).length;
  }

  int get _unmarkedCount {
    return _courseStudents.where((student) {
      return !_attendanceRecords.containsKey(student.id);
    }).length;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showMessage(String message) {
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildControls(),
                    const SizedBox(height: 20),
                    if (_selectedCourseId == null)
                      _buildSelectCourseState()
                    else
                      _buildAttendanceContent(),
                  ],
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------
// HEADER
// ------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage daily attendance for your students.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------
        // HISTORY BUTTON
        // --------------------------------------------------------

        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const AttendanceHistoryScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.history_rounded,
            size: 19,
          ),
          label: const Text('History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(
              color: Color(0xFFD5D5D5),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // --------------------------------------------------------
        // REFRESH BUTTON
        // --------------------------------------------------------

        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  // ------------------------------------------------------------
  // CONTROLS
  // ------------------------------------------------------------

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 650;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildDateSelector(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCourseDropdown(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildCourseDropdown(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE SELECTOR
  // ------------------------------------------------------------

  Widget _buildDateSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFDADADA),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COURSE DROPDOWN
  // ------------------------------------------------------------

  Widget _buildCourseDropdown() {
    final activeCourses = _courses.where((course) => course.isActive).toList();

    return DropdownButtonFormField<int>(
      value: _selectedCourseId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Course',
        prefixIcon: const Icon(
          Icons.menu_book_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFDADADA),
          ),
        ),
      ),
      hint: const Text('Choose a course'),
      items: activeCourses.map((course) {
        return DropdownMenuItem<int>(
          value: course.id,
          child: Text(
            course.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onCourseChanged,
    );
  }

  // ------------------------------------------------------------
  // SELECT COURSE STATE
  // ------------------------------------------------------------

  Widget _buildSelectCourseState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 40,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Select a course',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a course above to view its students '
            'and mark attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ATTENDANCE CONTENT
  // ------------------------------------------------------------

  Widget _buildAttendanceContent() {
    final students = _courseStudents;
    final course = _selectedCourse;

    if (students.isEmpty) {
      return _buildEmptyStudentsState(course);
    }

    return Column(
      children: [
        _buildCourseSummary(course, students),
        const SizedBox(height: 18),
        _buildQuickActions(),
        const SizedBox(height: 18),
        _buildStudentList(students),
        const SizedBox(height: 20),
        _buildSaveButton(),
      ],
    );
  }

  // ------------------------------------------------------------
  // COURSE SUMMARY
  // ------------------------------------------------------------

  Widget _buildCourseSummary(
    Course? course,
    List<Student> students,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 28,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course?.name ?? 'Course',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${students.length} active students',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildWhiteSummaryItem(
                'Present',
                _presentCount.toString(),
              ),
              _buildWhiteSummaryItem(
                'Absent',
                _absentCount.toString(),
              ),
              _buildWhiteSummaryItem(
                'Unmarked',
                _unmarkedCount.toString(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWhiteSummaryItem(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTIONS
  // ------------------------------------------------------------

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _markAllPresent,
            icon: const Icon(
              Icons.check_circle_outline_rounded,
            ),
            label: const Text('Mark All Present'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(
                color: Color(0xFFD5D5D5),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _markAllAbsent,
            icon: const Icon(
              Icons.cancel_outlined,
            ),
            label: const Text('Mark All Absent'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(
                color: Color(0xFFD5D5D5),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STUDENT LIST
  // ------------------------------------------------------------

  Widget _buildStudentList(List<Student> students) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              14,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${students.length} students',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFEAEAEA),
          ),
          ...students.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final student = entry.value;

              return _buildStudentAttendanceTile(
                student,
                index + 1,
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT ATTENDANCE TILE
  // ------------------------------------------------------------

  Widget _buildStudentAttendanceTile(
    Student student,
    int number,
  ) {
    final record = _attendanceRecords[student.id];

    final bool? isPresent = record == null ? null : record['isPresent'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEAEAEA),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentInfo(
                  student,
                  number,
                ),
                const SizedBox(height: 14),
                _buildStatusButtons(
                  student,
                  isPresent,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildStudentInfo(
                  student,
                  number,
                ),
              ),
              const SizedBox(width: 20),
              _buildStatusButtons(
                student,
                isPresent,
              ),
              if (record != null && record['id'] is int && record['id'] > 0)
                IconButton(
                  tooltip: 'Delete attendance',
                  onPressed:
                      _isSaving ? null : () => _deleteAttendance(student),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT INFO
  // ------------------------------------------------------------

  Widget _buildStudentInfo(
    Student student,
    int number,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                student.email,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STATUS BUTTONS
  // ------------------------------------------------------------

  Widget _buildStatusButtons(
    Student student,
    bool? isPresent,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusButton(
          label: 'Present',
          icon: Icons.check_rounded,
          selected: isPresent == true,
          onTap: () {
            _setAttendance(
              student.id,
              true,
            );
          },
        ),
        const SizedBox(width: 8),
        _buildStatusButton(
          label: 'Absent',
          icon: Icons.close_rounded,
          selected: isPresent == false,
          onTap: () {
            _setAttendance(
              student.id,
              false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: _isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFDADADA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE BUTTON
  // ------------------------------------------------------------

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _saveAttendance,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.save_outlined,
              ),
        label: Text(
          _isSaving ? 'Saving Attendance...' : 'Save Attendance',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STUDENTS
  // ------------------------------------------------------------

  Widget _buildEmptyStudentsState(Course? course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 65,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 58,
            color: Colors.black38,
          ),
          const SizedBox(height: 15),
          Text(
            'No active students',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'There are no active students assigned to '
            '${course?.name ?? 'this course'}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
