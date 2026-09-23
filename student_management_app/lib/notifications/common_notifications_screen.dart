import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_api_service.dart';
import '../assignments/assignments_screen.dart';

// ─── Design Tokens ───────────────────────────────────────────
class _C {
  static const black      = Color(0xFF0A0A0A);
  static const blackSoft  = Color(0xFF222222);
  static const blackMid   = Color(0xFF444444);
  static const grey       = Color(0xFF888888);
  static const greyLight  = Color(0xFFAAAAAA);
  static const border     = Color(0xFFE8E8E8);
  static const borderRead = Color(0xFFEBEBEB);
  static const bg         = Color(0xFFF5F5F5);
  static const cardUnread = Color(0xFFFFFFFF);
  static const cardRead   = Color(0xFFFAFAFA);
  static const iconUnread = Color(0xFF0A0A0A);
  static const iconRead   = Color(0xFFF0F0F0);
  static const dot        = Color(0xFF0A0A0A);
  static const label      = Color(0xFFF0F0F0);
  static const labelText  = Color(0xFF555555);
}

class CommonNotificationsScreen extends StatefulWidget {
  const CommonNotificationsScreen({super.key});

  @override
  State<CommonNotificationsScreen> createState() =>
      _CommonNotificationsScreenState();
}

class _CommonNotificationsScreenState
    extends State<CommonNotificationsScreen> {
  final NotificationApiService _notificationApiService =
  NotificationApiService();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading         = true;
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load notifications.')),
      );
    }
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================
  Future<void> _markAsRead(int notificationId, int index) async {
    try {
      await _notificationApiService.markAsRead(notificationId);
      if (!mounted) return;
      setState(() => _notifications[index]['isRead'] = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to mark notification as read.')),
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================
  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead) return;
    setState(() => _isMarkingAllAsRead = true);
    try {
      await _notificationApiService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
        }
        _isMarkingAllAsRead = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingAllAsRead = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to mark all notifications as read.')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => n['isRead'] == false)
        .length;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(unreadCount),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: _C.black,
                strokeWidth: 2,
              ),
            )
                : _notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              color: _C.black,
              onRefresh: _loadNotifications,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _buildSummaryRow(unreadCount),
                  const SizedBox(height: 14),
                  ...List.generate(
                    _notifications.length,
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNotificationCard(
                        _notifications[i],
                        i,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER  (dark — matches mockup)
  // ============================================================
  Widget _buildHeader(int unreadCount) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _C.black,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _todayLabel(),
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                if (unreadCount > 0)
                  GestureDetector(
                    onTap: _isMarkingAllAsRead ? null : _markAllAsRead,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: const Color(0xFF2A2A2A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isMarkingAllAsRead
                          ? const Center(
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.done_all_rounded,
                        color: Color(0xFF888888),
                        size: 18,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border:
                    Border.all(color: const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF888888),
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================
  Widget _buildSummaryRow(int unreadCount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unreadCount == 0
                    ? 'You are all caught up.'
                    : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _C.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Unread dot + count badge
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _C.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'UNREAD · $unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              '${_notifications.length} total',
              style: const TextStyle(
                color: _C.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================
  Widget _buildNotificationCard(
      Map<String, dynamic> notification,
      int index,
      ) {
    final notificationId = int.tryParse(
      notification['id']?.toString() ?? '',
    );
    final title     = notification['title']?.toString()     ?? 'Notification';
    final message   = notification['message']?.toString()   ?? '';
    final type      = notification['type']?.toString()      ?? '';
    final isRead    = notification['isRead'] == true;
    final createdAt = notification['createdAt']?.toString() ?? '';

    final icon      = _notificationIcon(type);
    final typeLabel = _notificationTypeLabel(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!isRead && notificationId != null) {
            await _markAsRead(notificationId, index);
          }
          final notificationType = type.toLowerCase();
          if (notificationType == 'submission') {
            final relatedId = int.tryParse(
              notification['relatedId']?.toString() ?? '',
            );
            if (relatedId != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignmentsScreen(
                    initialAssignmentId: relatedId,
                  ),
                ),
              );
              if (!mounted) return;
              await _loadNotifications();
            }
            return;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? _C.cardRead : _C.cardUnread,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? _C.borderRead : _C.border,
            ),
            boxShadow: isRead
                ? []
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Icon badge ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead ? _C.iconRead : _C.iconUnread,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isRead ? _C.blackMid : Colors.white,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Title + unread dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: isRead
                                  ? _C.blackSoft
                                  : _C.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: _C.dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Message
                    Text(
                      message,
                      style: TextStyle(
                        color: isRead
                            ? _C.greyLight
                            : _C.grey,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom row: type label + time + open arrow
                    Row(
                      children: [
                        // Type chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRead
                                ? const Color(0xFFF5F5F5)
                                : _C.label,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: isRead
                                  ? _C.greyLight
                                  : _C.labelText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Clock icon
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: isRead
                              ? _C.greyLight
                              : _C.grey,
                        ),
                        const SizedBox(width: 4),

                        // Date
                        Expanded(
                          child: Text(
                            createdAt.isNotEmpty
                                ? _formatDate(createdAt)
                                : '',
                            style: TextStyle(
                              color: isRead
                                  ? _C.greyLight
                                  : _C.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),

                        // Open arrow for submission
                        if (type.toLowerCase() == 'submission')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Open',
                                style: TextStyle(
                                  color: isRead
                                      ? _C.greyLight
                                      : _C.blackMid,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: isRead
                                    ? _C.greyLight
                                    : _C.blackMid,
                              ),
                            ],
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
    );
  }

  // ============================================================
  // ICON
  // ============================================================
  IconData _notificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'submission':  return Icons.assignment_turned_in_outlined;
      case 'assignment':  return Icons.assignment_outlined;
      case 'grade':       return Icons.school_outlined;
      case 'attendance':  return Icons.fact_check_outlined;
      case 'course':      return Icons.menu_book_outlined;
      default:            return Icons.notifications_none_rounded;
    }
  }

  // ============================================================
  // TYPE LABEL
  // ============================================================
  String _notificationTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'submission':  return 'SUBMISSION';
      case 'assignment':  return 'ASSIGNMENT';
      case 'grade':       return 'GRADE';
      case 'attendance':  return 'ATTENDANCE';
      case 'course':      return 'COURSE';
      default:            return 'NOTIFICATION';
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: _C.blackMid,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "You're all caught up",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _C.black,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no new notifications to show right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadNotifications,
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.black,
                side: const BorderSide(color: _C.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Refresh',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================
  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} '
        '${_monthName(d.month)} '
        '${d.year} • '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return months[month - 1];
  }

  // ============================================================
  // TODAY LABEL
  // ============================================================
  String _todayLabel() {
    final now = DateTime.now();
    const days   = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}