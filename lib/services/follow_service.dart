import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class FollowService {
  final _supabase = SupabaseConfig.client;
  final _notificationService = NotificationService();

  /// Check if current user is following a specific user
  Future<bool> isFollowing(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  /// Follow a user
  Future<void> followUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == userId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': userId,
      });

      // Create notification for the user being followed
      await _notificationService.createNotification(
        recipientUserId: userId,
        type: NotificationType.newFollower,
        actorId: currentUserId,
      );
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Get list of followers for a user
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('follower_id, users!follower_id(*)')
          .eq('following_id', userId);

      final followers = (response as List)
          .map((json) {
            // Try to get user data from the joined users table
            final userJson = json['users'] as Map<String, dynamic>?;
            if (userJson != null) {
              return UserModel.fromJson(userJson);
            }
            // Fallback: fetch user by ID if join didn't work
            return null;
          })
          .whereType<UserModel>()
          .toList();

      // If join didn't work, fetch users individually
      if (followers.isEmpty && (response as List).isNotEmpty) {
        final followerIds = (response as List)
            .map((json) => json['follower_id'] as String)
            .whereType<String>()
            .toList();
        
        for (final followerId in followerIds) {
          try {
            final userResponse = await _supabase
                .from('users')
                .select()
                .eq('id', followerId)
                .maybeSingle();
            if (userResponse != null) {
              followers.add(UserModel.fromJson(userResponse));
            }
          } catch (e) {
            print('Error fetching follower $followerId: $e');
          }
        }
      }

      return followers;
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  /// Get list of users that a user is following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id, users!following_id(*)')
          .eq('follower_id', userId);

      final following = (response as List)
          .map((json) {
            // Try to get user data from the joined users table
            final userJson = json['users'] as Map<String, dynamic>?;
            if (userJson != null) {
              return UserModel.fromJson(userJson);
            }
            return null;
          })
          .whereType<UserModel>()
          .toList();

      // If join didn't work, fetch users individually
      if (following.isEmpty && (response as List).isNotEmpty) {
        final followingIds = (response as List)
            .map((json) => json['following_id'] as String)
            .whereType<String>()
            .toList();
        
        for (final followingId in followingIds) {
          try {
            final userResponse = await _supabase
                .from('users')
                .select()
                .eq('id', followingId)
                .maybeSingle();
            if (userResponse != null) {
              following.add(UserModel.fromJson(userResponse));
            }
          } catch (e) {
            print('Error fetching following $followingId: $e');
          }
        }
      }

      return following;
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }
}

