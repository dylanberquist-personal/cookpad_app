import '../config/supabase_config.dart';

class SharingService {
  final _supabase = SupabaseConfig.client;

  // ============================================
  // RECIPE SHARING
  // ============================================

  /// Share a recipe with another user
  Future<void> shareRecipe(String recipeId, String recipientUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if already shared
    final existing = await _supabase
        .from('shared_recipes')
        .select()
        .eq('recipe_id', recipeId)
        .eq('sender_id', userId)
        .eq('recipient_id', recipientUserId)
        .maybeSingle();

    if (existing != null) {
      // Re-share: Delete the existing record and create a new one to trigger notification
      await _supabase
          .from('shared_recipes')
          .delete()
          .eq('recipe_id', recipeId)
          .eq('sender_id', userId)
          .eq('recipient_id', recipientUserId);
    }

    await _supabase.from('shared_recipes').insert({
      'recipe_id': recipeId,
      'sender_id': userId,
      'recipient_id': recipientUserId,
    });
  }

  /// Get recipes shared with the current user
  Future<List<String>> getSharedRecipeIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('shared_recipes')
        .select('recipe_id')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => json['recipe_id'] as String)
        .toList();
  }

  /// Delete a shared recipe
  Future<void> deleteSharedRecipe(String recipeId, String recipientUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('shared_recipes')
        .delete()
        .eq('recipe_id', recipeId)
        .eq('sender_id', userId)
        .eq('recipient_id', recipientUserId);
  }
}

