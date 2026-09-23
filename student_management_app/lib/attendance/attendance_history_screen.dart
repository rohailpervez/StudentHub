import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../services/attendance_api_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  final AttendanceApiService _attendanceApiService =
  AttendanceApiService();

  List<Attendance> _records = [];
  List<Attendance> _filteredRecords = [];

  bool _isLoading = true;

  String _searchQuery = '';
  int? _selectedCourseId;
  String _selectedStatus = 'All';

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ============================================================
  // LOAD HISTORY
  // ============================================================

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _attendanceApiService.getAttendance();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load attendance history: ${_cleanError(e)}',
      );
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _records.where((record) {
      final matchesSearch =
          query.isEmpty ||
              record.studentName.toLowerCase().contains(query) ||
              record.studentEmail.toLowerCase().contains(query) ||
              record.courseName.toLowerCase().contains(query);

      final matchesCourse =
          _selectedCourseId == null ||
              record.courseId == _selectedCourseId;

      final matchesStatus =
          _selectedStatus == 'All' ||
              (_selectedStatus == 'Present' && record.isPresent) ||
              (_selectedStatus == 'Absent' && !record.isPresent);

      bool matchesDate = true;

      if (_selectedDateRange != null) {
        final recordDate = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );

        final startDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );

        final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );

        matchesDate =
            !recordDate.isBefore(startDate) &&
                !recordDate.isAfter(endDate);
      }

      return matchesSearch &&
          matchesCourse &&
          matchesStatus &&
          matchesDate;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredRecords = filtered;
    });
  }

  // ============================================================
  // COURSE LIST
  // ============================================================

  List<Attendance> get _uniqueCourses {
    final seen = <int>{};
    final result = <Attendance>[];

    for (final record in _records) {
      if (seen.add(record.courseId)) {
        result.add(record);
      }
    }

    result.sort(
          (a, b) => a.courseName.compareTo(b.courseName),
    );

    return result;
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      helpText: 'Select attendance date range',
    );

    if (picked == null) return;

    setState(() {
      _selectedDateRange = picked;
    });

    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCourseId = null;
      _selectedStatus = 'All';
      _selectedDateRange = null;
    });

    _applyFilters();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get _presentCount {
    return _filteredRecords.where((record) => record.isPresent).length;
  }

  int get _absentCount {
    return _filteredRecords.where((record) => !record.isPresent).length;
  }

  double get _attendancePercentage {
    if (_filteredRecords.isEmpty) return 0;

    return (_presentCount / _filteredRecords.length) * 100;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAttendance(Attendance record) async {
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
                '${record.studentName} on ${_formatDate(record.date)}?',
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
      await _attendanceApiService.deleteAttendance(record.id);

      if (!mounted) return;

      setState(() {
        _records.removeWhere(
              (item) => item.id == record.id,
        );
      });

      _applyFilters();

      _showMessage(
        'Attendance deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete attendance: ${_cleanError(e)}',
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  String _formatDateRange(DateTimeRange range) {
    return '${_formatDate(range.start)} → '
        '${_formatDate(range.end)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSummary(),
              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 20),
              _buildHistoryList(),
            ],
          ),
        ),
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
                'Attendance History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View and manage previously recorded attendance.',
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
          onPressed: _loadHistory,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildSummaryCard(
            icon: Icons.fact_check_outlined,
            title: 'Total Records',
            value: _filteredRecords.length.toString(),
          ),
          _buildSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Present',
            value: _presentCount.toString(),
          ),
          _buildSummaryCard(
            icon: Icons.cancel_outlined,
            title: 'Absent',
            value: _absentCount.toString(),
          ),
          _buildSummaryCard(
            icon: Icons.percent_rounded,
            title: 'Attendance Rate',
            value:
            '${_attendancePercentage.toStringAsFixed(1)}%',
          ),
        ];

        if (constraints.maxWidth >= 900) {
          return Row(
            children: cards
                .map(
                  (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ),
              ),
            )
                .toList(),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            return SizedBox(
              width: constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.black,
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
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
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
    final courses = _uniqueCourses;

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
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildSearchField(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCourseFilter(courses),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusFilter(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildCourseFilter(courses),
                  const SizedBox(height: 12),
                  _buildStatusFilter(),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(
                    Icons.date_range_outlined,
                    size: 19,
                  ),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filter by Date Range'
                        : _formatDateRange(
                      _selectedDateRange!,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    side: const BorderSide(
                      color: Color(0xFFDADADA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Clear filters',
                onPressed: _clearFilters,
                icon: const Icon(
                  Icons.filter_alt_off_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        _searchQuery = value;
        _applyFilters();
      },
      decoration: InputDecoration(
        labelText: 'Search student or course',
        hintText: 'Name, email, or course',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFDADADA),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseFilter(List<Attendance> courses) {
    return DropdownButtonFormField<int?>(
      value: _selectedCourseId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Course',
        prefixIcon: const Icon(
          Icons.menu_book_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFDADADA),
          ),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All Courses'),
        ),
        ...courses.map(
              (course) => DropdownMenuItem<int?>(
            value: course.courseId,
            child: Text(
              course.courseName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCourseId = value;
        });

        _applyFilters();
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(
          Icons.check_circle_outline_rounded,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFDADADA),
          ),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'All',
          child: Text('All Status'),
        ),
        DropdownMenuItem(
          value: 'Present',
          child: Text('Present'),
        ),
        DropdownMenuItem(
          value: 'Absent',
          child: Text('Absent'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedStatus = value;
        });

        _applyFilters();
      },
    );
  }

  // ============================================================
  // HISTORY LIST
  // ============================================================

  Widget _buildHistoryList() {
    if (_filteredRecords.isEmpty) {
      return _buildEmptyState();
    }

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
                    'Attendance Records',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_filteredRecords.length} records',
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
          ..._filteredRecords.map(
                (record) => _buildHistoryTile(record),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Attendance record) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
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
                _buildStudentInfo(record),
                const SizedBox(height: 14),
                _buildRecordDetails(record),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(record),
                    const Spacer(),
                    _buildDeleteButton(record),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildStudentInfo(record),
              ),
              Expanded(
                flex: 2,
                child: _buildRecordDetails(record),
              ),
              _buildStatusBadge(record),
              const SizedBox(width: 8),
              _buildDeleteButton(record),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentInfo(Attendance record) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 21,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.studentName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.studentEmail,
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

  Widget _buildRecordDetails(Attendance record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 16,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                record.courseName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(
              _formatDate(record.date),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Attendance record) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: record.isPresent
            ? const Color(0xFFEFEFEF)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFDADADA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            record.isPresent
                ? Icons.check_rounded
                : Icons.close_rounded,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 5),
          Text(
            record.isPresent ? 'Present' : 'Absent',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(Attendance record) {
    return IconButton(
      tooltip: 'Delete attendance',
      onPressed: () => _deleteAttendance(record),
      icon: const Icon(
        Icons.delete_outline_rounded,
        size: 20,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
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
              Icons.history_rounded,
              size: 40,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _records.isEmpty
                ? 'No attendance has been recorded yet.'
                : 'No records match your current filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_records.isNotEmpty) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}