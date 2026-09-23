import 'package:flutter/material.dart';

import '../services/super_admin_api_service.dart';
import '../services/token_storage.dart';
import 'login_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final SuperAdminApiService _apiService = SuperAdminApiService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _organizations = [];

  // ============================================================
  // LOAD ORGANIZATIONS
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final organizations = await _apiService.getOrganizations();

      if (!mounted) return;

      setState(() {
        _organizations = organizations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

// ============================================================
// LOGOUT
// ============================================================

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final tokenStorage = TokenStorage();

      await tokenStorage.deleteToken();
      await tokenStorage.deleteUser();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DELETE ORGANIZATION
  // ============================================================

  Future<void> _deleteOrganization(
    int organizationId,
    String organizationName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Organization',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$organizationName"?\n\n'
            'This will also delete all related users, courses and students.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteOrganization(organizationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Organization deleted successfully.',
          ),
          backgroundColor: Colors.black,
        ),
      );

      await _loadOrganizations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ============================================================
  // ORGANIZATION DETAILS
  // ============================================================

  Future<void> _showOrganizationDetails(
    int organizationId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        );
      },
    );

    try {
      final organization = await _apiService.getOrganization(organizationId);

      if (!mounted) return;

      Navigator.pop(context);

      _showDetailsDialog(organization);
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ============================================================
  // DETAILS DIALOG
  // ============================================================

  void _showDetailsDialog(
    Map<String, dynamic> organization,
  ) {
    final users = (organization['users'] as List?) ?? [];

    final courses = (organization['courses'] as List?) ?? [];

    final students = (organization['students'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
              maxHeight: 650,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                organization['name']?.toString() ??
                                    'Organization',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Organization ID: ${organization['id']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // SUMMARY
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _summaryBox(
                            icon: Icons.people_alt_outlined,
                            label: 'Users',
                            value: users.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryBox(
                            icon: Icons.menu_book_outlined,
                            label: 'Courses',
                            value: courses.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryBox(
                            icon: Icons.school_outlined,
                            label: 'Students',
                            value: students.length.toString(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // USERS
                    // ==================================================

                    _sectionTitle(
                      icon: Icons.people_alt_outlined,
                      title: 'Users',
                    ),

                    const SizedBox(height: 10),

                    if (users.isEmpty)
                      _emptyMessage('No users found.')
                    else
                      ...users.map(
                        (user) => _userTile(
                          user as Map<String, dynamic>,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // COURSES
                    // ==================================================

                    _sectionTitle(
                      icon: Icons.menu_book_outlined,
                      title: 'Courses',
                    ),

                    const SizedBox(height: 10),

                    if (courses.isEmpty)
                      _emptyMessage('No courses found.')
                    else
                      ...courses.map(
                        (course) => _courseTile(
                          course as Map<String, dynamic>,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // STUDENTS
                    // ==================================================

                    _sectionTitle(
                      icon: Icons.school_outlined,
                      title: 'Students',
                    ),

                    const SizedBox(height: 10),

                    if (students.isEmpty)
                      _emptyMessage('No students found.')
                    else
                      ...students.map(
                        (student) => _studentTile(
                          student as Map<String, dynamic>,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SUMMARY BOX
  // ============================================================

  Widget _summaryBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.black,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USER TILE
  // ============================================================
  Widget _userTile(
    Map<String, dynamic> user,
  ) {
    final userId = (user['id'] as num?)?.toInt() ?? 0;
    final fullName = user['fullName']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black,
            child: Text(
              _initial(fullName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(
            user['isActive'] == true,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Delete user',
            onPressed: userId == 0
                ? null
                : () => _deleteUser(
                      userId,
                      fullName,
                    ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF4F4F4),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COURSE TILE
  // ============================================================

  Widget _courseTile(
    Map<String, dynamic> course,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['name']?.toString() ?? 'Course',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${course['durationMonths'] ?? 0} months',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(
            course['isActive'] == true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT TILE
  // ============================================================

  Widget _studentTile(
    Map<String, dynamic> student,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF0F0F0),
            child: const Icon(
              Icons.person_outline,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']?.toString() ?? 'Student',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student['email']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF1F1F1) : const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? Colors.black : Colors.red.shade700,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // ============================================================
  // INITIAL
  // ============================================================

  String _initial(String name) {
    if (name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'SuperAdmin',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadOrganizations,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _isLoading ? null : _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: _loadOrganizations,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY CONTENT
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadOrganizations,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      children: [
        // ========================================================
        // WELCOME
        // ========================================================

        const Text(
          'Welcome back, SuperAdmin',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Manage organizations, users and system data.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // STATS
        // ========================================================

        _buildStats(),

        const SizedBox(height: 30),

        // ========================================================
        // ORGANIZATIONS HEADER
        // ========================================================

        Row(
          children: [
            const Expanded(
              child: Text(
                'Organizations',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_organizations.length} total',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ========================================================
        // ORGANIZATION LIST
        // ========================================================

        if (_organizations.isEmpty)
          _buildEmptyOrganizations()
        else
          ..._organizations.map(
            (organization) => _buildOrganizationCard(
              organization as Map<String, dynamic>,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    int users = 0;
    int courses = 0;
    int students = 0;

    for (final organization in _organizations) {
      users += (organization['usersCount'] as num?)?.toInt() ?? 0;

      courses += (organization['coursesCount'] as num?)?.toInt() ?? 0;

      students += (organization['studentsCount'] as num?)?.toInt() ?? 0;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Organizations',
                value: _organizations.length.toString(),
                icon: Icons.business_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Users',
                value: users.toString(),
                icon: Icons.people_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Courses',
                value: courses.toString(),
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Students',
                value: students.toString(),
                icon: Icons.school_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORGANIZATION CARD
  // ============================================================

  Widget _buildOrganizationCard(
    Map<String, dynamic> organization,
  ) {
    final id = (organization['id'] as num?)?.toInt() ?? 0;

    final name = organization['name']?.toString() ?? 'Organization';

    final isActive = organization['isActive'] == true;

    final usersCount = (organization['usersCount'] as num?)?.toInt() ?? 0;

    final coursesCount = (organization['coursesCount'] as num?)?.toInt() ?? 0;

    final studentsCount = (organization['studentsCount'] as num?)?.toInt() ?? 0;

    final users = (organization['users'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // TOP
          // ======================================================

          Row(
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
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organization #$id',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(isActive),
            ],
          ),

          const SizedBox(height: 17),

          // ======================================================
          // COUNTS
          // ======================================================

          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _countItem(
                    Icons.people_outline,
                    'Users',
                    usersCount,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _countItem(
                    Icons.menu_book_outlined,
                    'Courses',
                    coursesCount,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _countItem(
                    Icons.school_outlined,
                    'Students',
                    studentsCount,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // CREATOR / FIRST USER
          // ======================================================

          if (users.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Primary user: '
                '${(users.first as Map<String, dynamic>)['fullName'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ======================================================
          // ACTIONS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showOrganizationDetails(id),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                  ),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Delete organization',
                onPressed: () => _deleteOrganization(id, name),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F4F4),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
// DELETE USER
// ============================================================

  Future<void> _deleteUser(
    int userId,
    String userName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete User',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$userName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteUser(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User deleted successfully.',
          ),
          backgroundColor: Colors.black,
        ),
      );

      await _loadOrganizations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // COUNT ITEM
  // ============================================================

  Widget _countItem(
    IconData icon,
    String label,
    int value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.black,
        ),
        const SizedBox(height: 5),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VERTICAL DIVIDER
  // ============================================================

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 35,
      color: const Color(0xFFE0E0E0),
    );
  }

  // ============================================================
  // EMPTY ORGANIZATIONS
  // ============================================================

  Widget _buildEmptyOrganizations() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.business_outlined,
            size: 45,
            color: Colors.black,
          ),
          const SizedBox(height: 14),
          const Text(
            'No organizations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Organizations created in StudentHub will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
