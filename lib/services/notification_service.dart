import '../config/supabase_config.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final _supabase = SupabaseConfig.client;
  
  // Rate limiting: 5 notifications per minute per user
  static const int _maxNotificationsPerMinute = 5;
  final Map<String, List<DateTime>> _notificationTimestamps = {};

  /// Check if user can send notifications (rate limiting)
  bool _canSendNotification(String userId) {
    final now = DateTime.now();
    final timestamps = _notificationTimestamps[userId] ?? [];
    
    // Remove timestamps older than 1 minute
    final recentTimestamps = timestamps.where((ts) {
      return now.difference(ts).inSeconds < 60;
    }).toList();
    
    _notificationTimestamps[userId] = recentTimestamps;
    
    return recentTimestamps.length < _maxNotificationsPerMinute;
  }

  /// Record a notification attempt for rate limiting
  void _recordNotification(String userId) {
    final now = DateTime.now();
    final timestamps = _notificationTimestamps[userId] ?? [];
    timestamps.add(now);
    _notificationTimestamps[userId] = timestamps;
  }

  /// Create a notification with rate limiting
  Future<void> createNotification({
    required String recipientUserId,
    required NotificationType type,
    required String actorId,
    String? recipeId,
    String? commentId,
  }) async {
    // Don't notify self
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || recipientUserId == currentUserId) {
      return;
    }

    // Rate limiting check
    if (!_canSendNotification(actorId)) {
      print('Rate limit exceeded: User $actorId has sent too many notifications');
      return;
    }

    // Check if notification already exists (avoid duplicates)
    final existingNotification = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', recipientUserId)
        .eq('type', type.name)
        .eq('actor_id', actorId)
        .eq('is_read', false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // If same unread notification exists within last 5 minutes, skip
    if (existingNotification != null) {
      final notification = await _supabase
          .from('notifications')
          .select('created_at')
          .eq('id', existingNotification['id'])
          .single();
      
      final createdAt = DateTime.parse(notification['created_at'] as String);
      final now = DateTime.now();
      if (now.difference(createdAt).inMinutes < 5) {
        return; // Skip duplicate notification
      }
    }

    try {
      await _supabase.from('notifications').insert({
        'user_id': recipientUserId,
        'type': type.name,
        'actor_id': actorId,
        'recipe_id': recipeId,
        'comment_id': commentId,
      });

      _recordNotification(actorId);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    var query = _supabase
        .from('notifications')
        .select('''
          *,
          actor:users!actor_id(
            id,
            username,
            display_name,
            profile_picture_url
          )
        ''')
        .eq('user_id', userId);

    if (isRead != null) {
      query = query.eq('is_read', isRead);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final notifications = (response as List)
        .map((json) => _notificationFromSupabaseJson(json))
        .toList();

    // Fetch recipe titles for recipe-related notifications
    final recipeIds = notifications
        .where((n) => n.recipeId != null)
        .map((n) => n.recipeId!)
        .toSet()
        .toList();

    Map<String, String> recipeTitles = {};
    if (recipeIds.isNotEmpty) {
      final recipesResponse = await _supabase
          .from('recipes')
          .select('id, title')
          .inFilter('id', recipeIds);

      for (var recipe in (recipesResponse as List)) {
        recipeTitles[recipe['id'] as String] = recipe['title'] as String;
      }
    }

    // Fetch comment content for comment notifications
    final commentIds = notifications
        .where((n) => n.commentId != null)
        .map((n) => n.commentId!)
        .toSet()
        .toList();

    Map<String, String> commentContents = {};
    if (commentIds.isNotEmpty) {
      final commentsResponse = await _supabase
          .from('comments')
          .select('id, content')
          .inFilter('id', commentIds);

      for (var comment in (commentsResponse as List)) {
        commentContents[comment['id'] as String] = comment['content'] as String;
      }
    }

    // Update notifications with fetched data
    return notifications.map((notification) {
      return NotificationModel(
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        actorId: notification.actorId,
        recipeId: notification.recipeId,
        commentId: notification.commentId,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
        actor: notification.actor,
        recipeTitle: notification.recipeId != null
            ? recipeTitles[notification.recipeId]
            : null,
        commentContent: notification.commentId != null
            ? commentContents[notification.commentId]
            : null,
      );
    }).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return 0;
    }

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  /// Parse notification from Supabase JSON
  NotificationModel _notificationFromSupabaseJson(Map<String, dynamic> json) {
    final actorJson = json['actor'] as Map<String, dynamic>?;
    UserModel? actor;
    if (actorJson != null) {
      try {
        actor = UserModel.fromJson(actorJson);
      } catch (e) {
        print('Error parsing actor: $e');
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      actorId: json['actor_id'] as String?,
      recipeId: json['recipe_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actor: actor,
    );
  }
}

