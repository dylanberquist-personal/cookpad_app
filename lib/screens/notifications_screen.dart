import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'recipe_detail_screen_new.dart';
import '../services/recipe_service_supabase.dart';
import 'my_profile_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onUnreadCountChanged;
  
  const NotificationsScreen({super.key, this.onUnreadCountChanged});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _recipeService = RecipeServiceSupabase();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _notifications = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications(
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        if (refresh) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _offset += notifications.length;
        _hasMore = notifications.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            actorId: notification.actorId,
            recipeId: notification.recipeId,
            commentId: notification.commentId,
            isRead: true,
            createdAt: notification.createdAt,
            actor: notification.actor,
            recipeTitle: notification.recipeTitle,
            commentContent: notification.commentContent,
          );
        }
      });
      // Notify parent of unread count change
      widget.onUnreadCountChanged?.call();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            actorId: n.actorId,
            recipeId: n.recipeId,
            commentId: n.commentId,
            isRead: true,
            createdAt: n.createdAt,
            actor: n.actor,
            recipeTitle: n.recipeTitle,
            commentContent: n.commentContent,
          );
        }).toList();
      });
      // Immediately notify parent of unread count change (no delay)
      widget.onUnreadCountChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking all as read: $e')),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read (this will also notify parent of unread count change)
    await _markAsRead(notification);

    // Navigate based on notification type
    if (notification.recipeId != null) {
      // Navigate to recipe detail screen
      if (mounted) {
        try {
          final recipe = await _recipeService.getRecipeById(notification.recipeId!);
          if (recipe != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreenNew(recipe: recipe),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading recipe: $e')),
            );
          }
        }
      }
    } else if (notification.actorId != null) {
      // For new follower notifications, navigate to actor's profile
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyProfileDetailScreen(userId: notification.actorId!),
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newFollower:
        return Colors.blue;
      case NotificationType.recipeFavorited:
        return Colors.red;
      case NotificationType.recipeRated:
        return Colors.amber;
      case NotificationType.comment:
        return Colors.green;
      case NotificationType.remix:
        return Colors.purple;
      case NotificationType.recipeImageAdded:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        // Load more indicator
                        _loadNotifications();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final notification = _notifications[index];
                      final isUnread = !notification.isRead;
                      final notificationColor = _getNotificationColor(notification.type);

                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      
                      return InkWell(
                        onTap: () => _handleNotificationTap(notification),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? notificationColor.withOpacity(isDark ? 0.15 : 0.05)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: notificationColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  notification.type.icon,
                                  color: notificationColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Actor info and timestamp
                                    Row(
                                      children: [
                                        if (notification.actor != null) ...[
                                          ClipOval(
                                            child: notification.actor!
                                                        .profilePictureUrl !=
                                                    null
                                                ? Image.network(
                                                    notification.actor!
                                                        .profilePictureUrl!,
                                                    width: 20,
                                                    height: 20,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (context, error,
                                                            stackTrace) {
                                                      return Container(
                                                        width: 20,
                                                        height: 20,
                                                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 12,
                                                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    width: 20,
                                                    height: 20,
                                                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 12,
                                                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            notification.actor!.username,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          _formatTimestamp(notification.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Message
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: isDark ? Colors.grey[100] : Colors.grey[800],
                                      ),
                                    ),
                                    // Recipe title if available
                                    if (notification.recipeTitle != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.recipeTitle!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Unread indicator
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: notificationColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
