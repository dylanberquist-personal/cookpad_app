import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../config/supabase_config.dart';

/// A stateful widget that displays a notification icon with a badge showing unread count
class NotificationBadgeIcon extends StatefulWidget {
  final bool isSelected;
  final double size;

  const NotificationBadgeIcon({
    super.key,
    this.isSelected = false,
    this.size = 20,
  });

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  final _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
      return;
    }

    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  String _formatUnreadCount(int count) {
    if (count == 0) return '';
    if (count < 10) return count.toString();
    return '10+';
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isSelected 
        ? Icon(Icons.notifications, size: widget.size)
        : Icon(Icons.notifications_outlined, size: widget.size);

    if (_unreadCount > 0) {
      return Badge(
        label: Text(
          _formatUnreadCount(_unreadCount),
          style: const TextStyle(fontSize: 10),
        ),
        child: icon,
      );
    }

    return icon;
  }
}

