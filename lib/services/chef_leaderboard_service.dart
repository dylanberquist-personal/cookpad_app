import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class ChefLeaderboardService {
  final _supabase = SupabaseConfig.client;

  /// Get top chefs by chef score
  Future<List<UserModel>> getTopChefs({int limit = 10}) async {
    final response = await _supabase
        .from('users')
        .select()
        .order('chef_score', ascending: false)
        .limit(limit);

    final users = (response as List)
        .map((json) => UserModel.fromJson(json))
        .toList();

    return users;
  }
}
