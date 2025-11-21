import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import 'block_service.dart';

class PersonalizedFeedService {
  final _supabase = SupabaseConfig.client;
  final _blockService = BlockService();

  /// Get personalized feed for the current user
  Future<List<RecipeModel>> getPersonalizedFeed({
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get user preferences
    final userResponse = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    final user = UserModel.fromJson(userResponse);
    final dietaryRestrictions = user.dietaryRestrictions;
    final cuisinePreferences = user.cuisinePreferences ?? [];

    // Get followed user IDs
    final followingResponse = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    
    final followedUserIds = (followingResponse as List)
        .map((json) => json['following_id'] as String)
        .toList();

    // Get user's favorited recipe IDs
    final favoritesResponse = await _supabase
        .from('favorites')
        .select('recipe_id')
        .eq('user_id', userId);
    
    final favoritedRecipeIds = (favoritesResponse as List)
        .map((json) => json['recipe_id'] as String)
        .toList();

    // Determine meal type based on time of day
    final currentHour = DateTime.now().hour;
    final suggestedMealType = _getMealTypeForHour(currentHour);

    // Get all public recipes with creator info
    final allRecipesResponse = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(200); // Get more to sort and filter

    var allRecipes = (allRecipesResponse as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();

    // Fetch images for all recipes
    if (allRecipes.isNotEmpty) {
      final recipeIds = allRecipes.map((r) => r.id).toList();
      final imagesResponse = await _supabase
          .from('recipe_images')
          .select('recipe_id, image_url, is_primary')
          .inFilter('recipe_id', recipeIds)
          .order('is_primary', ascending: false)
          .order('order');

      final Map<String, List<String>> imagesMap = {};
      final Map<String, List<Map<String, dynamic>>> imagesMapRaw = {};
      
      for (var image in (imagesResponse as List)) {
        final recipeId = image['recipe_id'] as String;
        if (!imagesMapRaw.containsKey(recipeId)) {
          imagesMapRaw[recipeId] = [];
        }
        imagesMapRaw[recipeId]!.add({
          'image_url': image['image_url'] as String,
          'is_primary': image['is_primary'] as bool? ?? false,
        });
      }

      imagesMapRaw.forEach((recipeId, images) {
        images.sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (a['is_primary'] != true && b['is_primary'] == true) return 1;
          return 0;
        });
        imagesMap[recipeId] = images.map((img) => img['image_url'] as String).toList();
      });

      // Attach images to recipes
      final recipesWithImages = allRecipes.map((recipe) {
        final imageUrls = imagesMap[recipe.id] ?? [];
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
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
          creator: recipe.creator,
        );
      }).toList();
      
      // Update allRecipes reference
      allRecipes = recipesWithImages;
    }

    // Get favorited recipe details for similarity matching
    List<RecipeModel> favoritedRecipes = [];
    if (favoritedRecipeIds.isNotEmpty) {
      final favRecipesResponse = await _supabase
          .from('recipes')
          .select('*, user:users!user_id(*)')
          .inFilter('id', favoritedRecipeIds);
      
      favoritedRecipes = (favRecipesResponse as List)
          .map((json) => _recipeFromSupabaseJson(json))
          .toList();
    }

    // Score and sort recipes
    final scoredRecipes = allRecipes.map((recipe) {
      double score = 0.0;

      // 1. Followed users (highest priority: +100)
      if (followedUserIds.contains(recipe.userId)) {
        score += 100;
      }

      // 2. Time-based meal type match (+50)
      if (recipe.mealType == suggestedMealType) {
        score += 50;
      }

      // 3. Similar to favorited recipes (+30-40 per match)
      for (var favRecipe in favoritedRecipes) {
        double similarity = _calculateSimilarity(recipe, favRecipe);
        score += similarity * 30;
      }

      // 4. Cuisine preferences match (+20)
      if (cuisinePreferences.isNotEmpty && recipe.cuisineType != null) {
        if (cuisinePreferences.contains(recipe.cuisineType)) {
          score += 20;
        }
      }

      // 5. Dietary restrictions match (+15)
      if (dietaryRestrictions.isNotEmpty && recipe.tags.isNotEmpty) {
        final recipeTags = recipe.tags.map((t) => t.toLowerCase()).toList();
        for (var restriction in dietaryRestrictions) {
          if (recipeTags.contains(restriction.toLowerCase())) {
            score += 15;
          }
        }
      }

      // 6. Trending/popular recipes (+10-25)
      // Higher ratings get more points
      if (recipe.averageRating > 0) {
        score += recipe.averageRating * 3; // Max 15 points for 5-star
      }
      
      // Recent favorites boost (+10)
      if (recipe.favoriteCount > 0) {
        score += (recipe.favoriteCount > 10 ? 10 : recipe.favoriteCount.toDouble());
      }
      
      // Recency boost (newer recipes get slight boost)
      final daysSinceCreation = DateTime.now().difference(recipe.createdAt).inDays;
      if (daysSinceCreation < 7) {
        score += (7 - daysSinceCreation) * 0.5; // Max ~3.5 points
      }

      return _ScoredRecipe(recipe: recipe, score: score);
    }).toList();

    // Filter out recipes from blocked users
    final blockedUserIds = await _blockService.getBlockedUserIds();
    if (blockedUserIds.isNotEmpty) {
      scoredRecipes.removeWhere((sr) => blockedUserIds.contains(sr.recipe.userId));
    }

    // Sort by score (descending) then by creation date (descending)
    scoredRecipes.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      return b.recipe.createdAt.compareTo(a.recipe.createdAt);
    });

    // Return paginated results
    final paginatedRecipes = scoredRecipes
        .skip(offset)
        .take(limit)
        .map((sr) => sr.recipe)
        .toList();

    return paginatedRecipes;
  }

  /// Determine meal type based on hour of day
  MealType _getMealTypeForHour(int hour) {
    if (hour >= 5 && hour < 11) {
      return MealType.breakfast;
    } else if (hour >= 11 && hour < 16) {
      return MealType.lunch;
    } else if (hour >= 16 && hour < 21) {
      return MealType.dinner;
    } else {
      return MealType.snack;
    }
  }

  /// Calculate similarity between two recipes
  double _calculateSimilarity(RecipeModel recipe1, RecipeModel recipe2) {
    double similarity = 0.0;

    // Same meal type
    if (recipe1.mealType == recipe2.mealType) {
      similarity += 0.3;
    }

    // Same cuisine type
    if (recipe1.cuisineType != null && recipe1.cuisineType == recipe2.cuisineType) {
      similarity += 0.3;
    }

    // Similar tags
    if (recipe1.tags.isNotEmpty && recipe2.tags.isNotEmpty) {
      final tags1 = recipe1.tags.map((t) => t.toLowerCase()).toSet();
      final tags2 = recipe2.tags.map((t) => t.toLowerCase()).toSet();
      final commonTags = tags1.intersection(tags2);
      if (tags1.length > 0) {
        similarity += (commonTags.length / tags1.length) * 0.2;
      }
    }

    // Similar ingredients (basic check)
    if (recipe1.ingredients.isNotEmpty && recipe2.ingredients.isNotEmpty) {
      final ingredients1 = recipe1.ingredients.map((i) => i.name.toLowerCase()).toSet();
      final ingredients2 = recipe2.ingredients.map((i) => i.name.toLowerCase()).toSet();
      final commonIngredients = ingredients1.intersection(ingredients2);
      if (ingredients1.length > 0) {
        similarity += (commonIngredients.length / ingredients1.length) * 0.2;
      }
    }

    return similarity.clamp(0.0, 1.0);
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

/// Helper class to store recipe with score
class _ScoredRecipe {
  final RecipeModel recipe;
  final double score;

  _ScoredRecipe({required this.recipe, required this.score});
}
