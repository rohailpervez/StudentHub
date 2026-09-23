import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';
import '../assignments/student_assignments_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../grades/student_academic_grades_screen.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  final NotificationApiService _notificationApiService =
      NotificationApiService();

  List<Map<String, dynamic>> _notifications = [];

  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

// ============================================================
// LOAD NOTIFICATIONS
// ============================================================

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to load notifications.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF323232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

// ============================================================
// MARK ONE AS READ
// ============================================================

  Future<void> _markAsRead(int id, int index) async {
    try {
      await _notificationApiService.markAsRead(id);

      if (!mounted) return;

      setState(() {
        _notifications[index]['isRead'] = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to mark notification as read.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF323232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

// ============================================================
// MARK ALL AS READ
// ============================================================

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead || _unreadCount == 0) return;

    try {
      setState(() {
        _isMarkingAllRead = true;
      });

      await _notificationApiService.markAllAsRead();

      if (!mounted) return;

      setState(() {
        for (final notification in _notifications) {
          notification['isRead'] = true;
        }

        _isMarkingAllRead = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All notifications marked as read.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isMarkingAllRead = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to mark all notifications as read.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF323232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

// ============================================================
// HELPERS
// ============================================================

  int get _unreadCount {
    return _notifications.where((notification) {
      return notification['isRead'] == false;
    }).length;
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_outlined;

      case 'grade':
        return Icons.grade_outlined;

      case 'attendance':
        return Icons.fact_check_outlined;

      case 'course':
        return Icons.menu_book_outlined;

      case 'submission':
        return Icons.upload_file_outlined;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _getNotificationLabel(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return 'Assignment';

      case 'grade':
        return 'Grade';

      case 'attendance':
        return 'Attendance';

      case 'course':
        return 'Course';

      case 'submission':
        return 'Submission';

      default:
        return 'Notification';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return const Color(0xFF2E7D32);

      case 'grade':
        return const Color(0xFF7B61FF);

      case 'attendance':
        return const Color(0xFF1976D2);

      case 'course':
        return const Color(0xFF00897B);

      case 'submission':
        return const Color(0xFFEF6C00);

      default:
        return const Color(0xFF546E7A);
    }
  }

  String _getRelativeTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();

      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF252525),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isMarkingAllRead ? null : _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isMarkingAllRead
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

// ============================================================
// BODY
// ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          28,
        ),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: 18),
          ...List.generate(
            _notifications.length,
            (index) {
              return _buildNotificationCard(
                _notifications[index],
                index,
              );
            },
          ),
        ],
      ),
    );
  }

// ============================================================
// SUMMARY HEADER
// ============================================================

  Widget _buildSummaryHeader() {
    final total = _notifications.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8ECF1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF2E7D32),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your notifications',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _unreadCount == 0
                      ? 'You are all caught up.'
                      : 'You have $_unreadCount unread '
                          '${_unreadCount == 1 ? 'notification' : 'notifications'}.',
                  style: const TextStyle(
                    color: Color(0xFF7A8491),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _unreadCount > 0
                  ? const Color(0xFFFFF3F3)
                  : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _unreadCount > 0 ? '$_unreadCount new' : '$total total',
              style: TextStyle(
                color: _unreadCount > 0
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF60746A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// EMPTY STATE
// ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 130),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'You are all caught up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'There are no new notifications right now. '
              'We will keep you updated here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A8491),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// NOTIFICATION CARD
// ============================================================

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    int index,
  ) {
    final bool isRead = notification['isRead'] == true;

    final String title = notification['title']?.toString() ?? 'Notification';

    final String message = notification['message']?.toString() ?? '';

    final String type = notification['type']?.toString() ?? '';

    final String createdAt = notification['createdAt']?.toString() ?? '';

    final int? notificationId =
        int.tryParse(notification['id']?.toString() ?? '');

    final Color typeColor = _getNotificationColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isRead ? const Color(0xFFE7EBF0) : const Color(0xFFCFE4D2),
          width: isRead ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isRead ? 0.025 : 0.045,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () async {
            if (!isRead && notificationId != null) {
              await _markAsRead(notificationId, index);
            }

            if (!mounted) return;

            final notificationType = type.toLowerCase();

            // ============================================================
// ACADEMIC GRADE NOTIFICATION
// ============================================================

            if (notificationType == 'grade' &&
                (notification['title'] == 'Academic Grade Added' ||
                    notification['title'] == 'Academic Grade Updated')) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentAcademicGradesScreen(),
                ),
              );

              if (!mounted) return;

              await _loadNotifications();

              return;
            }

            // ============================================================
            // ASSIGNMENT / GRADE NOTIFICATION
            // ============================================================

            if (notificationType == 'assignment' ||
                notificationType == 'grade') {
              final relatedId = int.tryParse(
                notification['relatedId']?.toString() ?? '',
              );

              if (relatedId != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAssignmentsScreen(
                      initialAssignmentId: relatedId,
                    ),
                  ),
                );

                if (!mounted) return;

                await _loadNotifications();
              }

              return;
            }

            // ============================================================
            // COURSE NOTIFICATION
            // ============================================================

            if (notificationType == 'course') {
              final courseId = int.tryParse(
                notification['relatedId']?.toString() ?? '',
              );

              if (courseId != null) {
                Navigator.pop(
                  context,
                  {
                    'type': 'Course',
                    'courseId': courseId,
                  },
                );
              }

              return;
            }

            // ============================================================
// ATTENDANCE NOTIFICATION
// ============================================================

            if (notificationType == 'attendance') {
              final courseId = int.tryParse(
                notification['relatedId']?.toString() ?? '',
              );

              if (courseId != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAttendanceScreen(
                      initialCourseId: courseId,
                    ),
                  ),
                );

                if (!mounted) return;

                await _loadNotifications();
              }

              return;
            }

          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
// ==================================================
// ICON
// ==================================================

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: typeColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

// ==================================================
// CONTENT
// ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
// TITLE + UNREAD DOT
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: const Color(0xFF1F2937),
                                fontSize: 15.5,
                                height: 1.3,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(
                                left: 8,
                                top: 5,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 7),

// MESSAGE
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 12),

// TYPE + TIME
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              _getNotificationLabel(type),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB8BEC6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _getRelativeTime(createdAt),
                            style: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
