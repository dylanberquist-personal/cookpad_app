import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';

class BadgeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all badges earned by a user
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final response = await _supabase
          .from('user_badges')
          .select('badge_id, awarded_at, badges(*)')
          .eq('user_id', userId)
          .order('awarded_at', ascending: false);

      return (response as List).map((item) {
        final badgeData = item['badges'] as Map<String, dynamic>;
        badgeData['awarded_at'] = item['awarded_at'];
        return BadgeModel.fromJson(badgeData);
      }).toList();
    } catch (e) {
      print('Error fetching user badges: $e');
      return [];
    }
  }

  /// Get all available badges (for showing locked/unlocked states)
  Future<List<BadgeModel>> getAllBadges() async {
    try {
      final response = await _supabase
          .from('badges')
          .select()
          .order('requirement_value', ascending: true);

      return (response as List)
          .map((json) => BadgeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all badges: $e');
      return [];
    }
  }

  /// Get all badges with user's earned status
  Future<Map<String, dynamic>> getBadgesWithStatus(String userId) async {
    try {
      // Get all badges
      final allBadges = await getAllBadges();
      
      // Get user's earned badges
      final earnedBadges = await getUserBadges(userId);
      final earnedBadgeIds = earnedBadges.map((b) => b.id).toSet();

      // Separate into earned and locked
      final earned = allBadges.where((b) => earnedBadgeIds.contains(b.id)).toList();
      final locked = allBadges.where((b) => !earnedBadgeIds.contains(b.id)).toList();

      return {
        'earned': earned,
        'locked': locked,
        'totalEarned': earned.length,
        'totalAvailable': allBadges.length,
      };
    } catch (e) {
      print('Error fetching badges with status: $e');
      return {
        'earned': <BadgeModel>[],
        'locked': <BadgeModel>[],
        'totalEarned': 0,
        'totalAvailable': 0,
      };
    }
  }

  /// Get user's most prestigious badges (top tier or most recent)
  Future<List<BadgeModel>> getTopBadges(String userId, {int limit = 3}) async {
    try {
      final badges = await getUserBadges(userId);
      
      // Sort by tier priority (platinum > gold > silver > bronze) then by awarded date
      badges.sort((a, b) {
        final tierPriority = {
          'platinum': 4,
          'gold': 3,
          'silver': 2,
          'bronze': 1,
        };
        
        final aPriority = tierPriority[a.tier] ?? 0;
        final bPriority = tierPriority[b.tier] ?? 0;
        
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority); // Higher tier first
        }
        
        // Same tier, sort by most recent
        return (b.awardedAt ?? DateTime.now())
            .compareTo(a.awardedAt ?? DateTime.now());
      });

      return badges.take(limit).toList();
    } catch (e) {
      print('Error fetching top badges: $e');
      return [];
    }
  }

  /// Get badge statistics for a user
  Future<Map<String, dynamic>> getBadgeStats(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      
      final bronzeCount = badges.where((b) => b.tier == 'bronze').length;
      final silverCount = badges.where((b) => b.tier == 'silver').length;
      final goldCount = badges.where((b) => b.tier == 'gold').length;
      final platinumCount = badges.where((b) => b.tier == 'platinum').length;

      return {
        'total': badges.length,
        'bronze': bronzeCount,
        'silver': silverCount,
        'gold': goldCount,
        'platinum': platinumCount,
      };
    } catch (e) {
      print('Error fetching badge stats: $e');
      return {
        'total': 0,
        'bronze': 0,
        'silver': 0,
        'gold': 0,
        'platinum': 0,
      };
    }
  }
}

