import '../config/supabase_config.dart';

enum ReportAction {
  resolve,
  dismiss,
  deleteRecipe,
  deleteComment,
  deleteImage,
  suspendUser,
}

class AdminService {
  final _supabase = SupabaseConfig.client;

  /// Check if current user is an admin
  /// Note: You'll need to implement your admin check logic
  /// This could be a role in the users table, a separate admins table, etc.
  Future<bool> isAdmin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // TODO: Implement your admin check logic
    // Example: Check if user has admin role
    // final user = await _supabase
    //     .from('users')
    //     .select('role')
    //     .eq('id', userId)
    //     .single();
    // return user['role'] == 'admin';
    
    // For now, return false - implement based on your needs
    return false;
  }

  /// Resolve a report with notes
  Future<void> resolveReport({
    required String reportId,
    String? notes,
    String? actionTaken,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('resolve_report', params: {
      'report_id_param': reportId,
      'admin_user_id': userId,
      'notes': notes,
      'action_taken_param': actionTaken,
    });
  }

  /// Delete a reported recipe
  Future<void> deleteReportedRecipe({
    required String recipeId,
    String? notes,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('delete_reported_recipe', params: {
      'recipe_id_param': recipeId,
      'admin_user_id': userId,
      'notes': notes,
    });
  }

  /// Delete a reported comment
  Future<void> deleteReportedComment({
    required String commentId,
    String? notes,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('delete_reported_comment', params: {
      'comment_id_param': commentId,
      'admin_user_id': userId,
      'notes': notes,
    });
  }

  /// Delete a reported recipe image
  Future<void> deleteReportedRecipeImage({
    required String imageUrl,
    required String recipeId,
    String? notes,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('delete_reported_recipe_image', params: {
      'image_url_param': imageUrl,
      'recipe_id_param': recipeId,
      'admin_user_id': userId,
      'notes': notes,
    });
  }

  /// Suspend a reported user
  Future<void> suspendReportedUser({
    required String userId,
    String? notes,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final adminUserId = _supabase.auth.currentUser?.id;
    if (adminUserId == null) throw Exception('User not authenticated');

    await _supabase.rpc('suspend_reported_user', params: {
      'user_id_param': userId,
      'admin_user_id': adminUserId,
      'notes': notes,
    });
  }

  /// Dismiss a report (mark as false positive)
  Future<void> dismissReport({
    required String reportId,
    String? notes,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('dismiss_report', params: {
      'report_id_param': reportId,
      'admin_user_id': userId,
      'notes': notes,
    });
  }

  /// Get all reports with context (for admin review)
  Future<List<Map<String, dynamic>>> getReportsForReview({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    var query = _supabase
        .from('report_review_view')
        .select('*');

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get high-priority reports
  Future<List<Map<String, dynamic>>> getHighPriorityReports() async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final result = await _supabase.rpc('get_high_priority_reports');
    return (result as List).cast<Map<String, dynamic>>();
  }

  /// Get admin action history
  Future<List<Map<String, dynamic>>> getAdminActions({
    int daysBack = 30,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final result = await _supabase.rpc('get_admin_actions', params: {
      'admin_user_id': userId,
      'days_back': daysBack,
    });

    return (result as List).cast<Map<String, dynamic>>();
  }
}

