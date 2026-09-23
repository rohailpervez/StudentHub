import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/course.dart';
import '../services/student_api_service.dart';
import '../services/auth_api_service.dart';

import 'student_list_screen.dart';
import 'courses_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';

import '../setting/settings_screen.dart';
import '../user/users_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StudentApiService _apiService = StudentApiService();
  final AuthApiService _authApiService = AuthApiService();

  List<Student> _students = [];
  List<Course> _courses = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _userName = 'User';
  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  // ============================================================
  // LOAD USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    try {
      final user = await _authApiService.getSavedUser();

      if (!mounted || user == null) return;

      final fullName = user['fullName']?.toString().trim();
      final role = user['role']?.toString().trim();

      setState(() {
        _userName = fullName != null && fullName.isNotEmpty ? fullName : 'User';

        _userRole = role != null && role.isNotEmpty ? role : 'User';
      });
    } catch (_) {
      // Keep default values.
    }
  }

  // ============================================================
  // USER INITIALS
  // ============================================================

  String get _userInitials {
    final name = _userName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
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

      final students = results[0] as List<Student>;
      final courses = results[1] as List<Course>;

      if (!mounted) return;

      setState(() {
        _students = students;
        _courses = courses;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard data.';
      });
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get _totalStudents => _students.length;

  int get _totalCourses => _courses.length;

  int get _activeCourses => _courses.where((course) => course.isActive).length;

  int get _studentsWithEmail =>
      _students.where((student) => student.email.trim().isNotEmpty).length;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF111111),
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        32,
                        30,
                        32,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 28),
                          _buildStatistics(),
                          const SizedBox(height: 30),
                          _buildRecentStudents(),
                        ],
                      ),
                    ),
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
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 258,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          // LOGO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF111111),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'StudentHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 44),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: Color(0xFF707070),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _sidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            selected: true,
          ),

          _sidebarItem(
            icon: Icons.people_alt_rounded,
            title: 'Students',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentListScreen(),
                ),
              );

              _loadDashboardData();
            },
          ),

          _sidebarItem(
            icon: Icons.menu_book_rounded,
            title: 'Courses',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CoursesScreen(),
                ),
              );

              _loadDashboardData();
            },
          ),

          _sidebarItem(
            icon: Icons.manage_accounts_rounded,
            title: 'Users',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UsersScreen(),
                ),
              );
            },
          ),

          _sidebarItem(
            icon: Icons.bar_chart_rounded,
            title: 'Reports',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportsScreen(),
                ),
              );

              _loadDashboardData();
            },
          ),

          const Spacer(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'SYSTEM',
              style: TextStyle(
                color: Color(0xFF707070),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _sidebarItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );

              _loadDashboardData();
            },
          ),

          _sidebarItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: _logout,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR ITEM
  // ============================================================

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2B2B2B) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 24,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 1,
        ),
        leading: Icon(
          icon,
          size: 21,
          color: selected ? Colors.white : const Color(0xFF999999),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF999999),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
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
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // User pressed Cancel or closed the dialog
    if (shouldLogout != true) {
      return;
    }

    // Logout
    await _authApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8E9EC),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              letterSpacing: -0.4,
            ),
          ),

          const Spacer(),

          // REFRESH
          _topBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboardData,
          ),

          const SizedBox(width: 8),

          // NOTIFICATIONS
          _topBarIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: () {},
          ),

          const SizedBox(width: 18),

          Container(
            height: 40,
            width: 1,
            color: const Color(0xFFE8E8E8),
          ),

          const SizedBox(width: 18),

          // USER AVATAR
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 11),

          // USER INFO
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 150,
                ),
                child: Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userRole,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topBarIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 20,
          color: const Color(0xFF444444),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME SECTION
  // ============================================================

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $_userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your students, courses and academic activity from one place.',
                style: TextStyle(
                  color: Color(0xFFB7B7B7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          );

          final status = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'API Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 18),
                status,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              status,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1050) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cards = _isLoading
            ? List.generate(
                4,
                (_) => _loadingStatCard(),
              )
            : [
                _statCard(
                  title: 'Total Students',
                  value: '$_totalStudents',
                  icon: Icons.people_alt_rounded,
                  subtitle: 'Registered students',
                ),
                _statCard(
                  title: 'Total Courses',
                  value: '$_totalCourses',
                  icon: Icons.menu_book_rounded,
                  subtitle: 'Available courses',
                ),
                _statCard(
                  title: 'Active Courses',
                  value: '$_activeCourses',
                  icon: Icons.check_circle_outline_rounded,
                  subtitle: 'Currently active',
                ),
                _statCard(
                  title: 'With Email',
                  value: '$_studentsWithEmail',
                  icon: Icons.email_outlined,
                  subtitle: 'Students with email',
                ),
              ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 160,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }

  // ============================================================
  // LOADING CARD
  // ============================================================

  Widget _loadingStatCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE8E9EC),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7E8EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF222222),
                  size: 21,
                ),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF999999),
                  size: 19,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT STUDENTS
  // ============================================================

  Widget _buildRecentStudents() {
    if (_isLoading) {
      return _loadingRecentStudents();
    }

    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    final recentStudents = _students.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE7E8EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Students',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Latest student records from your organization',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentListScreen(),
                    ),
                  );

                  _loadDashboardData();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF111111),
                ),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                ),
                label: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentStudents.isEmpty)
            _buildNoStudents()
          else
            Column(
              children: recentStudents.map(_studentRow).toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT ROW
  // ============================================================

  Widget _studentRow(Student student) {
    final firstLetter = student.name.isNotEmpty
        ? student.name.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDEDED),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
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
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    student.course.isNotEmpty ? student.course : 'No course',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${student.id}',
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO STUDENTS
  // ============================================================

  Widget _buildNoStudents() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 31,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No students found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Add your first student to get started.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING RECENT STUDENTS
  // ============================================================

  Widget _loadingRecentStudents() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE7E8EB),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE7E8EB),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 31,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Make sure the ASP.NET Core API is running.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
