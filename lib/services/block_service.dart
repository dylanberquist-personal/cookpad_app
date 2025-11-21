import '../config/supabase_config.dart';

class BlockService {
  final _supabase = SupabaseConfig.client;

  /// Block a user
  Future<void> blockUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == userId) {
      throw Exception('Cannot block yourself');
    }

    // Check if already blocked
    final existing = await _supabase
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', userId)
        .maybeSingle();

    if (existing != null) {
      return; // Already blocked
    }

    // Create block
    await _supabase.from('user_blocks').insert({
      'blocker_id': currentUserId,
      'blocked_id': userId,
    });
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('user_blocks')
        .delete()
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', userId);
  }

  /// Check if a user is blocked by current user
  Future<bool> isBlocked(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return false;
    }

    final result = await _supabase
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', userId)
        .maybeSingle();

    return result != null;
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedBy(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return false;
    }

    final result = await _supabase
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', userId)
        .eq('blocked_id', currentUserId)
        .maybeSingle();

    return result != null;
  }

  /// Get list of blocked user IDs for current user
  Future<List<String>> getBlockedUserIds() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return [];
    }

    final response = await _supabase
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', currentUserId);

    return (response as List)
        .map((json) => json['blocked_id'] as String)
        .toList();
  }

  /// Get list of user IDs who have blocked current user
  Future<List<String>> getBlockedByUserIds() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return [];
    }

    final response = await _supabase
        .from('user_blocks')
        .select('blocker_id')
        .eq('blocked_id', currentUserId);

    return (response as List)
        .map((json) => json['blocker_id'] as String)
        .toList();
  }
}

