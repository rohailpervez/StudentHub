import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/token_storage.dart';
import '../attendance/attendance_screen.dart';
import 'student_list_screen.dart';
import 'courses_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import '../services/notification_api_service.dart';
import '../assignments/assignments_screen.dart';
import '../grades/academic_grades_screen.dart';
import '../notifications/common_notifications_screen.dart';

class CommonDashboardScreen extends StatefulWidget {
  const CommonDashboardScreen({super.key});
  @override
  State<CommonDashboardScreen> createState() => _CommonDashboardScreenState();
}
class _CommonDashboardScreenState extends State<CommonDashboardScreen> {
  int _selectedIndex = 0;
  final TokenStorage _tokenStorage = TokenStorage();
  final NotificationApiService _notificationApiService =
  NotificationApiService();

  int _unreadNotificationCount = 0;
  String _userName = 'My Account';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await _tokenStorage.getUser();

      if (userData == null || userData.isEmpty) {
        return;
      }

      final decodedUser = jsonDecode(userData);

      if (!mounted) return;

      setState(() {
        _userName = decodedUser['fullName']?.toString() ??
            decodedUser['name']?.toString() ??
            'My Account';
      });
    } catch (e) {
      // Keep dashboard working if user data fails to load.
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications =
      await _notificationApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = notifications
            .where(
              (notification) =>
          notification['isRead'] == false,
        )
            .length;
      });
    } catch (e) {
      // Keep dashboard working if notifications fail to load.
    }
  }
  // ============================================================
  // MENU
  // ============================================================
  final List<_MenuItem> _menuItems = const [
    _MenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
    ),
    _MenuItem(
      title: 'Students',
      icon: Icons.people_outline_rounded,
    ),
    _MenuItem(
      title: 'Courses',
      icon: Icons.menu_book_outlined,
    ),
    _MenuItem(
      title: 'Attendance',
      icon: Icons.fact_check_outlined,
    ),
    _MenuItem(
      title: 'Reports',
      icon: Icons.bar_chart_outlined,
    ),
    _MenuItem(
      title: 'Assignments',
      icon: Icons.assignment_outlined,
    ),
    _MenuItem(
      title: 'Academic Grades',
      icon: Icons.school_outlined,
    ),
  ];
  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
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
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (shouldLogout != true) return;
    try {
      // Remove JWT token
      await _tokenStorage.deleteToken();
      // Remove saved user data
      await _tokenStorage.deleteUser();
      if (!mounted) return;
      // Go directly to LoginScreen.
      // This also removes all previous dashboard screens.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to logout. Please try again.',
          ),
        ),
      );
    }
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
      width: 250,
      color: Colors.black,
      child: Column(
        children: [
          // ------------------------------------------------------
          // LOGO
          // ------------------------------------------------------
          SizedBox(
            height: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'StudentHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            color: Color(0xFF303030),
            height: 1,
          ),
          const SizedBox(height: 22),
          // ------------------------------------------------------
          // MENU
          // ------------------------------------------------------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final selected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 21,
                            color: selected ? Colors.black : Colors.white70,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white70,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ------------------------------------------------------
          // LOGOUT BUTTON
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 19,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFF444444),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
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
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _menuItems[_selectedIndex].title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const CommonNotificationsScreen(),
                    ),
                  );

                  if (!mounted) return;

                  _loadUnreadNotificationCount();
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                ),
              ),

              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 2,
                  top: 0,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
  // CURRENT PAGE
  // ============================================================
  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 1:
        return const StudentListScreen();
      case 2:
        return const CoursesScreen();
      case 3:
        return const AttendanceScreen();
      case 4:
        return const ReportsScreen();
      case 5:
        return const AssignmentsScreen();
      case 6:
        return const AcademicGradesScreen();
      default:
        return _buildHome();
    }
  }
  // ============================================================
  // HOME
  // ============================================================
  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to StudentHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'View your organization information from one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width >= 1000
                  ? (width - 48) / 4
                  : width >= 650
                  ? (width - 16) / 2
                  : width;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildOverviewCard(
                    width: cardWidth,
                    icon: Icons.people_outline_rounded,
                    title: 'Students',
                    subtitle: 'View students',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  _buildOverviewCard(
                    width: cardWidth,
                    icon: Icons.menu_book_outlined,
                    title: 'Courses',
                    subtitle: 'View courses',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  _buildOverviewCard(
                    width: cardWidth,
                    icon: Icons.bar_chart_outlined,
                    title: 'Reports',
                    subtitle: 'View reports',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                  ),
                  _buildOverviewCard(
                    width: cardWidth,
                    icon: Icons.business_outlined,
                    title: 'Organization',
                    subtitle: 'Your organization',
                    onTap: () {},
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Access',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Students',
                  description: 'View students from your organization.',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAccessCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Courses',
                  description: 'View courses from your organization.',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFE3E3E3),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.black,
                  size: 23,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View-only access',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Students, courses and reports can be viewed '
                            'from this dashboard. Adding, editing and deleting '
                            'records is available only to authorized administrators.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
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
  // OVERVIEW CARD
  // ============================================================
  Widget _buildOverviewCard({
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE3E3E3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // QUICK ACCESS CARD
  // ============================================================
  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE3E3E3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 24,
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
// ================================================================
// MENU ITEM MODEL
// ================================================================
class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem({
    required this.title,
    required this.icon,
  });
}