import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _notifications = MockDataService.getMockNotifications();
  }

  String _formatTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  List<Map<String, dynamic>> _getGroup(String group) {
    final now = DateTime.now();
    return _notifications.where((n) {
      final createdAt = n['createdAt'] as DateTime;
      final diff = now.difference(createdAt);
      if (group == 'today') return diff.inHours < 24;
      if (group == 'week') return diff.inHours >= 24 && diff.inDays <= 7;
      return diff.inDays > 7;
    }).toList();
  }

  void _markAllRead() {
    MockDataService.markAllNotificationsRead();
    setState(() {
      _notifications = MockDataService.getMockNotifications();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      case 'reel_like':
        return Icons.play_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'like':
      case 'reel_like':
        return AppColors.like;
      case 'comment':
        return AppColors.comment;
      case 'follow':
        return AppColors.accent;
      case 'mention':
        return AppColors.warning;
      default:
        return AppColors.neutral400;
    }
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final isUnread = !(notif['isRead'] as bool);
    final type = notif['type'] as String;
    return Container(
      decoration: BoxDecoration(
        color:
            isUnread ? AppColors.accent.withOpacity(0.05) : Colors.transparent,
        border: isUnread
            ? const Border(
                left: BorderSide(color: AppColors.accent, width: 3),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(isUnread ? 13 : 16, 8, 16, 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              imageUrl: notif['profileImageUrl'],
              fallbackName: notif['username'] ?? 'U',
              radius: 24,
            ),
            Positioned(
              bottom: -2,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(type),
                  size: 12,
                  color: _colorForType(type),
                ),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: '${notif['username']} ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: notif['message']),
              TextSpan(
                text: '  ${_formatTime(notif['createdAt'])}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: notif['postImageUrl'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  notif['postImageUrl'],
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            : type == 'follow'
                ? OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutral300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Follow back',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                    ),
                  )
                : null,
        onTap: () {
          if (notif['postId'] != null) {
            context.push('/post/${notif['postId']}');
          } else if (notif['uid'] != null) {
            context.push('/user/${notif['uid']}');
          }
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        ...items.map(_buildNotificationTile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _getGroup('today');
    final week = _getGroup('week');
    final earlier = _getGroup('earlier');
    final hasUnread = _notifications.any((n) => !(n['isRead'] as bool));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 72, color: AppColors.neutral300),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                _buildSection('Today', today),
                _buildSection('This Week', week),
                _buildSection('Earlier', earlier),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
