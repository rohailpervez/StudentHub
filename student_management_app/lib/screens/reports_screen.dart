import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/course.dart';
import '../services/student_api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final StudentApiService _apiService = StudentApiService();

  List<Student> _students = [];
  List<Course> _courses = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadReports() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.getStudents(),
        _apiService.getCourses(),
      ]);

      if (!mounted) return;

      setState(() {
        _students = results[0] as List<Student>;
        _courses = results[1] as List<Course>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load report data.';
      });
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get _totalStudents => _students.length;

  int get _totalCourses => _courses.length;

  int get _activeCourses =>
      _courses.where((course) => course.isActive).length;

  int get _inactiveCourses =>
      _courses.where((course) => !course.isActive).length;

  int get _studentsWithEmail =>
      _students.where((student) => student.email.trim().isNotEmpty).length;

  int get _studentsWithPhone =>
      _students.where((student) => student.phone.trim().isNotEmpty).length;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF111111),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E5E5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 30,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load reports',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadReports,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 900;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            compact ? 18 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1400,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(compact),
                  const SizedBox(height: 26),
                  _buildOverviewCards(compact),
                  const SizedBox(height: 26),
                  _buildChartsSection(compact),
                  const SizedBox(height: 26),
                  _buildContactOverview(compact),
                  const SizedBox(height: 26),
                  _buildCourseDetails(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 20 : 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerText(),
          const SizedBox(height: 20),
          _refreshButton(),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _headerText(),
          ),
          _refreshButton(),
        ],
      ),
    );
  }

  Widget _headerText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'A complete overview of students, courses and contact information.',
          style: TextStyle(
            color: Color(0xFFB7B7B7),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _refreshButton() {
    return OutlinedButton.icon(
      onPressed: _loadReports,
      icon: const Icon(
        Icons.refresh_rounded,
        size: 18,
      ),
      label: const Text('Refresh Data'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(
          color: Color(0xFF555555),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARDS
  // ============================================================

  Widget _buildOverviewCards(bool compact) {
    final cards = [
      _reportCard(
        title: 'Total Students',
        value: '$_totalStudents',
        subtitle: 'Registered students',
        icon: Icons.people_alt_rounded,
      ),
      _reportCard(
        title: 'Total Courses',
        value: '$_totalCourses',
        subtitle: 'Courses in system',
        icon: Icons.menu_book_rounded,
      ),
      _reportCard(
        title: 'Active Courses',
        value: '$_activeCourses',
        subtitle: 'Currently active',
        icon: Icons.check_circle_outline_rounded,
      ),
      _reportCard(
        title: 'Inactive Courses',
        value: '$_inactiveCourses',
        subtitle: 'Currently inactive',
        icon: Icons.pause_circle_outline_rounded,
      ),
      _reportCard(
        title: 'With Email',
        value: '$_studentsWithEmail',
        subtitle: 'Students with email',
        icon: Icons.email_outlined,
      ),
      _reportCard(
        title: 'With Phone',
        value: '$_studentsWithPhone',
        subtitle: 'Students with phone',
        icon: Icons.phone_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
                .toList(),
          );
        }

        if (constraints.maxWidth < 1000) {
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: cards
                .map(
                  (card) => SizedBox(
                width: (constraints.maxWidth - 14) / 2,
                child: card,
              ),
            )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
            const SizedBox(width: 14),
            Expanded(child: cards[4]),
            const SizedBox(width: 14),
            Expanded(child: cards[5]),
          ],
        );
      },
    );
  }

  Widget _reportCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
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
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
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
  // CHARTS
  // ============================================================

  Widget _buildChartsSection(bool compact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 900;

        final courseChart = _buildCourseDistribution();
        final statusChart = _buildCourseStatus();

        if (stacked) {
          return Column(
            children: [
              courseChart,
              const SizedBox(height: 18),
              statusChart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: courseChart),
            const SizedBox(width: 18),
            Expanded(child: statusChart),
          ],
        );
      },
    );
  }

  // ============================================================
  // MULTIPLE COURSE DISTRIBUTION
  // ============================================================

  Widget _buildCourseDistribution() {
    final courseCounts = <int, int>{};

    // A student can now belong to multiple courses.
    // Count every course in student.courseIds.
    for (final student in _students) {
      for (final courseId in student.courseIds) {
        courseCounts[courseId] =
            (courseCounts[courseId] ?? 0) + 1;
      }
    }

    final courseItems = _courses.map((course) {
      return MapEntry(
        course,
        courseCounts[course.id] ?? 0,
      );
    }).toList();

    courseItems.sort(
          (a, b) => b.value.compareTo(a.value),
    );

    final int maxCount = courseItems.isEmpty
        ? 0
        : courseItems
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b);

    return _chartCard(
      title: 'Students by Course',
      subtitle: 'Number of students enrolled in each course',
      icon: Icons.bar_chart_rounded,
      child: courseItems.isEmpty
          ? _emptyChart('No course data available')
          : Column(
        children: courseItems
            .map(
              (item) => _courseBar(
            courseName: item.key.name,
            count: item.value,
            maxCount: maxCount,
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _courseBar({
    required String courseName,
    required int count,
    required int maxCount,
  }) {
    final double percentage =
    maxCount == 0 ? 0 : count / maxCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  courseName.isEmpty ? 'Unnamed Course' : courseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count students',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 9,
              backgroundColor: const Color(0xFFEDEDED),
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatus() {
    final int total = _activeCourses + _inactiveCourses;

    final double activePercentage =
    total == 0 ? 0 : _activeCourses / total;

    final double inactivePercentage =
    total == 0 ? 0 : _inactiveCourses / total;

    return _chartCard(
      title: 'Course Status',
      subtitle: 'Active and inactive courses',
      icon: Icons.donut_large_rounded,
      child: Column(
        children: [
          const SizedBox(height: 6),
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : activePercentage,
                    strokeWidth: 24,
                    backgroundColor: const Color(0xFFE8E8E8),
                    color: const Color(0xFF222222),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_totalCourses',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const Text(
                      'Courses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _statusRow(
            label: 'Active Courses',
            value: _activeCourses,
            percentage: activePercentage,
            indicatorColor: const Color(0xFF222222),
          ),
          const SizedBox(height: 13),
          _statusRow(
            label: 'Inactive Courses',
            value: _inactiveCourses,
            percentage: inactivePercentage,
            indicatorColor: const Color(0xFFBDBDBD),
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required String label,
    required int value,
    required double percentage,
    required Color indicatorColor,
  }) {
    final int percent = (percentage * 100).round();

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF222222),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT OVERVIEW
  // ============================================================

  Widget _buildContactOverview(bool compact) {
    final int noEmail =
        _totalStudents - _studentsWithEmail;

    final int noPhone =
        _totalStudents - _studentsWithPhone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Student contact information availability',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _contactItem(
                      icon: Icons.email_outlined,
                      title: 'Email Available',
                      value: _studentsWithEmail,
                      total: _totalStudents,
                    ),
                    const SizedBox(height: 12),
                    _contactItem(
                      icon: Icons.email_outlined,
                      title: 'Email Missing',
                      value: noEmail,
                      total: _totalStudents,
                    ),
                    const SizedBox(height: 12),
                    _contactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Available',
                      value: _studentsWithPhone,
                      total: _totalStudents,
                    ),
                    const SizedBox(height: 12),
                    _contactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Missing',
                      value: noPhone,
                      total: _totalStudents,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _contactItem(
                      icon: Icons.email_outlined,
                      title: 'Email Available',
                      value: _studentsWithEmail,
                      total: _totalStudents,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _contactItem(
                      icon: Icons.email_outlined,
                      title: 'Email Missing',
                      value: noEmail,
                      total: _totalStudents,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _contactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Available',
                      value: _studentsWithPhone,
                      total: _totalStudents,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _contactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Missing',
                      value: noPhone,
                      total: _totalStudents,
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

  Widget _contactItem({
    required IconData icon,
    required String title,
    required int value,
    required int total,
  }) {
    final int percentage =
    total == 0 ? 0 : ((value / total) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
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
  // COURSE DETAILS
  // ============================================================

  Widget _buildCourseDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Current course status and student distribution',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          if (_courses.isEmpty)
            _emptyChart('No courses available')
          else
            ..._courses.map(
                  (course) => _courseDetailRow(course),
            ),
        ],
      ),
    );
  }

  Widget _courseDetailRow(Course course) {
    // A student may be enrolled in multiple courses.
    // Count the student if this course exists in courseIds.
    final int studentCount = _students
        .where(
          (student) => student.courseIds.contains(course.id),
    )
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 20,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name.isEmpty
                      ? 'Unnamed Course'
                      : course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${course.durationMonths} month${course.durationMonths == 1 ? '' : 's'} • $studentCount student${studentCount == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: course.isActive
                  ? const Color(0xFFEDEDED)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              course.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: course.isActive
                    ? const Color(0xFF222222)
                    : const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }
}