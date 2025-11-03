import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';

class RecipeServiceSupabase {
  final _supabase = SupabaseConfig.client;

  Future<List<RecipeModel>> getRecipes({
    String? userId,
    bool? isPublic,
    int limit = 50,
    int offset = 0,
    String? orderBy,
    bool ascending = false,
  }) async {
    final queryBuilder = _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)');

    PostgrestFilterBuilder? filteredQuery;
    if (userId != null && isPublic != null) {
      filteredQuery = queryBuilder.eq('user_id', userId).eq('is_public', isPublic);
    } else if (userId != null) {
      filteredQuery = queryBuilder.eq('user_id', userId);
    } else if (isPublic != null) {
      filteredQuery = queryBuilder.eq('is_public', isPublic);
    }

    final orderedQuery = filteredQuery ?? queryBuilder;
    final sortedQuery = orderBy != null
        ? orderedQuery.order(orderBy, ascending: ascending)
        : orderedQuery.order('created_at', ascending: false);

    final response = await sortedQuery.range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();
  }

  Future<RecipeModel?> getRecipeById(String recipeId, {String? currentUserId}) async {
    final response = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .eq('id', recipeId)
        .single();

    final recipe = _recipeFromSupabaseJson(response);

    // Check if favorited and rated by current user
    if (currentUserId != null) {
      final favorite = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', currentUserId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      final rating = await _supabase
          .from('ratings')
          .select()
          .eq('user_id', currentUserId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return RecipeModel(
        id: recipe.id,
        userId: recipe.userId,
        title: recipe.title,
        description: recipe.description,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        totalTime: recipe.totalTime,
        servings: recipe.servings,
        difficultyLevel: recipe.difficultyLevel,
        cuisineType: recipe.cuisineType,
        mealType: recipe.mealType,
        nutrition: recipe.nutrition,
        tags: recipe.tags,
        sourceType: recipe.sourceType,
        sourceUrl: recipe.sourceUrl,
        isPublic: recipe.isPublic,
        averageRating: recipe.averageRating,
        ratingCount: recipe.ratingCount,
        favoriteCount: recipe.favoriteCount,
        createdAt: recipe.createdAt,
        updatedAt: recipe.updatedAt,
        imageUrls: recipe.imageUrls,
        isFavorite: favorite != null,
        userRating: rating != null ? (rating['rating'] as int) : null,
        creator: recipe.creator,
      );
    }

    return recipe;
  }

  Future<List<String>> getRecipeImages(String recipeId) async {
    final response = await _supabase
        .from('recipe_images')
        .select('image_url')
        .eq('recipe_id', recipeId)
        .order('order')
        .order('is_primary', ascending: false);

    return (response as List)
        .map((json) => json['image_url'] as String)
        .toList();
  }

  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final recipeData = {
      'user_id': userId,
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients.map((i) => i.toJson()).toList(),
      'instructions': recipe.instructions.map((i) => i.toJson()).toList(),
      'prep_time': recipe.prepTime,
      'cook_time': recipe.cookTime,
      'total_time': recipe.totalTime,
      'servings': recipe.servings,
      'difficulty_level': recipe.difficultyLevel.name,
      'cuisine_type': recipe.cuisineType,
      'meal_type': recipe.mealType.name,
      'nutrition': recipe.nutrition?.toJson(),
      'tags': recipe.tags,
      'source_type': recipe.sourceType.name,
      'source_url': recipe.sourceUrl,
      'is_public': recipe.isPublic,
    };

    final response = await _supabase
        .from('recipes')
        .insert(recipeData)
        .select()
        .single();

    final recipeId = response['id'] as String;

    // Upload images if provided
    if (recipe.imageUrls != null && recipe.imageUrls!.isNotEmpty) {
      for (int i = 0; i < recipe.imageUrls!.length; i++) {
        await _supabase.from('recipe_images').insert({
          'recipe_id': recipeId,
          'image_url': recipe.imageUrls![i],
          'is_primary': i == 0,
          'order': i,
        });
      }
    }

    final createdRecipe = await getRecipeById(recipeId);
    return createdRecipe ?? recipe;
  }

  Future<RecipeModel> updateRecipe(RecipeModel recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (recipe.userId != userId) throw Exception('Unauthorized');

    final recipeData = {
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients.map((i) => i.toJson()).toList(),
      'instructions': recipe.instructions.map((i) => i.toJson()).toList(),
      'prep_time': recipe.prepTime,
      'cook_time': recipe.cookTime,
      'total_time': recipe.totalTime,
      'servings': recipe.servings,
      'difficulty_level': recipe.difficultyLevel.name,
      'cuisine_type': recipe.cuisineType,
      'meal_type': recipe.mealType.name,
      'nutrition': recipe.nutrition?.toJson(),
      'tags': recipe.tags,
      'source_url': recipe.sourceUrl,
      'is_public': recipe.isPublic,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from('recipes')
        .update(recipeData)
        .eq('id', recipe.id);

    final updatedRecipe = await getRecipeById(recipe.id);
    return updatedRecipe ?? recipe;
  }

  Future<void> deleteRecipe(String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final recipe = await getRecipeById(recipeId);
    if (recipe?.userId != userId) throw Exception('Unauthorized');

    await _supabase.from('recipes').delete().eq('id', recipeId);
  }

  Future<void> toggleFavorite(String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    } else {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    }
  }

  Future<void> rateRecipe(String recipeId, int rating) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (rating < 1 || rating > 5) throw Exception('Rating must be between 1 and 5');

    await _supabase.from('ratings').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'rating': rating,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,recipe_id');
  }

  Future<List<RecipeModel>> getFavoriteRecipes({String? userId}) async {
    final currentUserId = userId ?? _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('favorites')
        .select('recipe_id')
        .eq('user_id', currentUserId);

    final recipeIds = (response as List)
        .map((json) => json['recipe_id'] as String)
        .toList();

    if (recipeIds.isEmpty) return [];

    final recipes = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .inFilter('id', recipeIds);

    return (recipes as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();
  }

  Future<List<RecipeModel>> searchRecipes(String query) async {
    final response = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .or('title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();
  }

  RecipeModel _recipeFromSupabaseJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    final user = userData != null ? UserModel.fromJson(userData) : null;

    final recipe = RecipeModel.fromJson(json);
    return RecipeModel(
      id: recipe.id,
      userId: recipe.userId,
      title: recipe.title,
      description: recipe.description,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      totalTime: recipe.totalTime,
      servings: recipe.servings,
      difficultyLevel: recipe.difficultyLevel,
      cuisineType: recipe.cuisineType,
      mealType: recipe.mealType,
      nutrition: recipe.nutrition,
      tags: recipe.tags,
      sourceType: recipe.sourceType,
      sourceUrl: recipe.sourceUrl,
      isPublic: recipe.isPublic,
      averageRating: recipe.averageRating,
      ratingCount: recipe.ratingCount,
      favoriteCount: recipe.favoriteCount,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
      creator: user,
    );
  }
}
