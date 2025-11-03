import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<CommentModel>> listComments(String recipeId, {String? currentUserId}) async {
    final response = await _supabase
        .from('comments')
        .select('*, user:users!user_id(id, username, profile_picture_url)')
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: true);

    final comments = (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();

    // Fetch favorite status for each comment if user is authenticated
    if (currentUserId != null && comments.isNotEmpty) {
      try {
        final commentIds = comments.map((c) => c.id).toList();
        final favoritesResponse = await _supabase
            .from('comment_favorites')
            .select('comment_id')
            .eq('user_id', currentUserId)
            .inFilter('comment_id', commentIds);

        final favoritedCommentIds = (favoritesResponse as List)
            .map((json) => json['comment_id'] as String)
            .toSet();

        return comments.map((comment) {
          return CommentModel(
            id: comment.id,
            userId: comment.userId,
            recipeId: comment.recipeId,
            parentCommentId: comment.parentCommentId,
            content: comment.content,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            username: comment.username,
            profilePictureUrl: comment.profilePictureUrl,
            isFavorite: favoritedCommentIds.contains(comment.id),
          );
        }).toList();
      } catch (e) {
        // If comment_favorites table doesn't exist yet, return comments without favorite status
        // This allows the app to work before the migration is run
        print('Warning: Could not fetch comment favorites: $e');
        return comments.map((comment) {
          return CommentModel(
            id: comment.id,
            userId: comment.userId,
            recipeId: comment.recipeId,
            parentCommentId: comment.parentCommentId,
            content: comment.content,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            username: comment.username,
            profilePictureUrl: comment.profilePictureUrl,
            isFavorite: false,
          );
        }).toList();
      }
    }

    return comments;
  }

  Future<CommentModel> addComment({
    required String recipeId,
    required String content,
    String? parentCommentId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Validate comment length
    if (content.length > 255) {
      throw Exception('Comment must be 255 characters or less');
    }

    // Ensure user exists in users table
    await _ensureUserExists(userId);

    final insert = {
      'user_id': userId,
      'recipe_id': recipeId,
      'parent_comment_id': parentCommentId,
      'content': content,
    };

    final response = await _supabase
        .from('comments')
        .insert(insert)
        .select('*, user:users!user_id(id, username, profile_picture_url)')
        .single();

    return CommentModel.fromJson(response);
  }

  Future<void> _ensureUserExists(String userId) async {
    // Check if user exists in users table
    final existingUser = await _supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existingUser == null) {
      // Get user email from auth
      final authUser = _supabase.auth.currentUser;
      if (authUser == null || authUser.id != userId) {
        throw Exception('User not authenticated');
      }

      // Create user record in users table
      final email = authUser.email ?? '';
      var username = email.split('@').first;
      
      // Check if username already exists, append numbers if needed
      int counter = 1;
      var finalUsername = username;
      while (true) {
        final exists = await _supabase
            .from('users')
            .select('id')
            .eq('username', finalUsername)
            .maybeSingle();
        
        if (exists == null) break;
        finalUsername = '$username$counter';
        counter++;
      }

      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': finalUsername,
        'skill_level': 'beginner',
        'dietary_restrictions': [],
        'chef_score': 0.0,
      });
    }
  }

  Future<void> toggleFavoriteComment(String commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final existing = await _supabase
          .from('comment_favorites')
          .select()
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('comment_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
      } else {
        await _supabase.from('comment_favorites').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
      }
    } catch (e) {
      // If comment_favorites table doesn't exist yet, throw a helpful error
      if (e.toString().contains('comment_favorites') || e.toString().contains('PGRST205')) {
        throw Exception('Comment favorites feature not available. Please run the migration to create the comment_favorites table.');
      }
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if user is comment owner or recipe owner
    final comment = await _supabase
        .from('comments')
        .select('*, recipe:recipes!recipe_id(user_id)')
        .eq('id', commentId)
        .single();

    final recipeOwnerId = (comment['recipe'] as Map<String, dynamic>)['user_id'] as String;
    
    if (comment['user_id'] != userId && recipeOwnerId != userId) {
      throw Exception('Unauthorized: Only comment owner or recipe owner can delete');
    }

    await _supabase
        .from('comments')
        .delete()
        .eq('id', commentId);
  }
}
