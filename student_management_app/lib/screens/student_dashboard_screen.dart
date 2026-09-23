import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_api_service.dart';
import '../attendance/student_attendance_screen.dart';
import '../assignments/student_assignments_screen.dart';
import '../grades/student_academic_grades_screen.dart';
import '../profile/student_profile_screen.dart';
import '../services/notification_api_service.dart';
import '../notifications/student_notifications_screen.dart';
import '../services/token_storage.dart';
import 'login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends State<StudentDashboardScreen> {
  final StudentApiService _apiService = StudentApiService();
  final NotificationApiService _notificationApiService =
  NotificationApiService();

  int _unreadNotificationCount = 0;

  int _selectedIndex = 0;

  Student? _student;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _menuItems = [
    'Dashboard',
    'My Subjects',
    'Assignments',
    'Quizzes',
    'My Attendance',
    'Exams & Results',
    'My Profile',
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_rounded,
    Icons.menu_book_rounded,
    Icons.assignment_rounded,
    Icons.quiz_rounded,
    Icons.calendar_month_rounded,
    Icons.school_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _loadUnreadNotificationCount();
  }

  // ============================================================
  // LOAD LOGGED-IN STUDENT
  // ============================================================

  Future<void> _loadStudent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final student = await _apiService.getMyStudent();

      if (!mounted) return;

      setState(() {
        _student = student;
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

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications =
      await _notificationApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = notifications.where((notification) {
          return notification['isRead'] == false;
        }).length;
      });
    } catch (_) {

    }
  }

  // ============================================================
  // OPEN COURSE FROM NOTIFICATION
  // ============================================================

  void openCourseFromNotification(int courseId) {
    final student = _student;

    if (student == null) {
      return;
    }

    final courseIndex = student.courseIds.indexOf(courseId);

    if (courseIndex == -1 ||
        courseIndex >= student.courses.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Course is no longer assigned to you.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _selectedIndex = 1;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildCurrentPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 255,
      color: const Color(0xFF111111),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF111111),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'StudentHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 42),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'STUDENT PORTAL',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Menu
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _menuIcons[index],
                            size: 19,
                            color: isSelected
                                ? const Color(0xFF111111)
                                : Colors.white.withValues(
                              alpha: 0.62,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              _menuItems[index],
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF111111)
                                    : Colors.white.withValues(
                                  alpha: 0.72,
                                ),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 17,
                              color: Color(0xFF111111),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Student mini profile
          if (_student != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAvatar(
                      name: _student!.name,
                      size: 36,
                      dark: true,
                      profilePicturePath: _student!.profilePicturePath,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _student!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Student Account',
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.42,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: _showLogoutDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 19,
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                    const SizedBox(width: 13),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final studentName = _student?.name ?? 'Student';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
          Text(
            _menuItems[_selectedIndex],
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              letterSpacing: -0.3,
            ),
          ),

          const Spacer(),

          // Refresh
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadStudent,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF555555),
              size: 21,
            ),
          ),

          const SizedBox(width: 4),

          // Notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const StudentNotificationsScreen(),
                    ),
                  );

                  if (!mounted) return;

                  _loadUnreadNotificationCount();

                  if (result is Map<String, dynamic> &&
                      result['type'] == 'Course') {
                    final courseId = result['courseId'];

                    if (courseId is int) {
                      openCourseFromNotification(courseId);
                    }
                  }
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF555555),
                  size: 22,
                ),
              ),

              // Unread notification badge
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 4,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : _unreadNotificationCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(11),
            ),
            child: _student == null
                ? const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Color(0xFF333333),
            )
                : _buildAvatar(
              name: studentName,
              size: 38,
              profilePicturePath: _student!.profilePicturePath,
            ),
          ),

          const SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Student',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();

      case 1:
        return _buildSubjectsPage();

      case 2:
        return const StudentAssignmentsScreen();

      case 3:
        return _buildComingSoonPage(
          icon: Icons.quiz_outlined,
          title: 'Quizzes',
          description:
          'Your quizzes and pending attempts will appear here.',
        );

      case 4:
        return const StudentAttendanceScreen();

      case 5:
        return const StudentAcademicGradesScreen();

      case 6:
        return const StudentProfileScreen();

      default:
        return _buildDashboardHome();
    }
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF777777),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE4E4E4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF333333),
                size: 27,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadStudent,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD HOME
  // ============================================================

  Widget _buildDashboardHome() {
    final student = _student;

    if (student == null) {
      return const SizedBox.shrink();
    }

    final subjects = student.courses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome hero
          _buildWelcomeCard(student),

          const SizedBox(height: 28),

          // Academic overview
          const Text(
            'Academic Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'My Subjects',
                  value: subjects.length.toString(),
                  subtitle: subjects.isEmpty
                      ? 'No subjects'
                      : 'Enrolled subjects',
                  icon: Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: 'Assignments',
                  value: '—',
                  subtitle: 'Coming soon',
                  icon: Icons.assignment_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: 'Attendance',
                  value: '—',
                  subtitle: 'Not available yet',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: 'Quizzes',
                  value: '—',
                  subtitle: 'Coming soon',
                  icon: Icons.quiz_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Subjects + Academic information
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildSubjectsCard(),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildAcademicStatusCard(),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildRecentActivityEmptyCard(),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard(Student student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(
                      name: student.name,
                      size: 44,
                      dark: true,
                      profilePicturePath: student.profilePicturePath,
                    ),
                    const SizedBox(width: 13),
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  'Welcome back, ${student.name} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Keep track of your subjects and stay updated with your academic journey.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF111111),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
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
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF222222),
                  size: 19,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: Color(0xFFAAAAAA),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF777777),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECTS CARD
  // ============================================================

  Widget _buildSubjectsCard() {
    final subjects = _student?.courses ?? [];

    return _buildCard(
      title: 'My Subjects',
      trailing: TextButton(
        onPressed: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
        child: const Text(
          'View All',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: subjects.isEmpty
          ? _buildEmptyContent(
        icon: Icons.menu_book_outlined,
        title: 'No subjects assigned',
        description:
        'Your enrolled subjects will appear here.',
      )
          : Column(
        children: [
          for (int i = 0; i < subjects.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == subjects.length - 1 ? 0 : 12,
              ),
              child: _buildSubjectRow(
                id: i + 1,
                name: subjects[i],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT ROW
  // ============================================================

  Widget _buildSubjectRow({
    required int id,
    required String name,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _selectedIndex = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFFEDEDED),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Subject ID: $id',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACADEMIC STATUS
  // ============================================================

  Widget _buildAcademicStatusCard() {
    return _buildCard(
      title: 'Academic Status',
      child: Column(
        children: [
          _buildStatusRow(
            icon: Icons.verified_outlined,
            title: 'Account Status',
            value: _student?.isActive == true
                ? 'Active'
                : 'Inactive',
          ),
          const Divider(height: 24),
          _buildStatusRow(
            icon: Icons.school_outlined,
            title: 'Student ID',
            value: _student?.id.toString() ?? '—',
          ),
          const Divider(height: 24),
          _buildStatusRow(
            icon: Icons.menu_book_outlined,
            title: 'Subjects',
            value: (_student?.courses.length ?? 0).toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF222222),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF777777),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ACTIVITY EMPTY
  // ============================================================

  Widget _buildRecentActivityEmptyCard() {
    return _buildCard(
      title: 'Recent Activity',
      child: _buildEmptyContent(
        icon: Icons.history_rounded,
        title: 'No recent activity',
        description:
        'Assignments, quizzes, attendance and results will appear here as your academic activity grows.',
      ),
    );
  }

  // ============================================================
  // SUBJECTS PAGE
  // ============================================================

  Widget _buildSubjectsPage() {
    final subjects = _student?.courses ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageIntro(
            title: 'My Subjects',
            description:
            'View the subjects you are currently enrolled in.',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 22),
          if (subjects.isEmpty)
            _buildCard(
              title: 'Subjects',
              child: _buildEmptyContent(
                icon: Icons.menu_book_outlined,
                title: 'No subjects found',
                description:
                'You currently have no subjects assigned to your account.',
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.55,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                return _buildSubjectLargeCard(
                  id: index + 1,
                  name: subject,
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LARGE SUBJECT CARD
  // ============================================================

  Widget _buildSubjectLargeCard({
    required int id,
    required String name,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Subject ID: $id',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMING SOON / EMPTY MODULE
  // ============================================================

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageIntro(
            title: title,
            description: description,
            icon: icon,
          ),
          const SizedBox(height: 22),
          _buildCard(
            title: title,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 55,
              ),
              child: _buildEmptyContent(
                icon: icon,
                title: '$title are not available yet',
                description: description,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE INTRO
  // ============================================================

  Widget _buildPageIntro({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY CONTENT
  // ============================================================

  Widget _buildEmptyContent({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 15,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF444444),
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ============================================================
// AVATAR
// ============================================================

  Widget _buildAvatar({
    required String name,
    required double size,
    bool dark = false,
    String? profilePicturePath,
  }) {
    final initial = name.trim().isEmpty
        ? 'S'
        : name.trim().substring(0, 1).toUpperCase();

    final imageUrl = profilePicturePath != null &&
        profilePicturePath.trim().isNotEmpty
        ? 'http://localhost:5083${profilePicturePath.trim()}'
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white
            : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(
          size * 0.28,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null
          ? Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            initial,
            style: TextStyle(
              color: dark
                  ? const Color(0xFF111111)
                  : Colors.white,
              fontSize: size * 0.40,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      )
          : Text(
        initial,
        style: TextStyle(
          color: dark
              ? const Color(0xFF111111)
              : Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                // Close logout dialog first
                Navigator.pop(dialogContext);

                // Clear authentication data
                final tokenStorage = TokenStorage();

                await tokenStorage.deleteToken();
                await tokenStorage.deleteUser();

                if (!mounted) return;

                // Go directly to LoginScreen
                // and remove all previous screens from navigation stack.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}