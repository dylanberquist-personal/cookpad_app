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

    final recipes = (response as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();

    // Fetch images for all recipes in batch
    if (recipes.isNotEmpty) {
      final recipeIds = recipes.map((r) => r.id).toList();
      final imagesResponse = await _supabase
          .from('recipe_images')
          .select('recipe_id, image_url, is_primary')
          .inFilter('recipe_id', recipeIds)
          .order('is_primary', ascending: false)
          .order('order');

      // Group images by recipe_id, ensuring primary images are first
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

      // Sort each recipe's images to ensure primary comes first
      final Map<String, List<String>> imagesMap = {};
      imagesMapRaw.forEach((recipeId, images) {
        images.sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (a['is_primary'] != true && b['is_primary'] == true) return 1;
          return 0;
        });
        imagesMap[recipeId] = images.map((img) => img['image_url'] as String).toList();
      });

      // Update recipes with their images
      return recipes.map((recipe) {
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
    }

    return recipes;
  }

  Future<RecipeModel?> getRecipeById(String recipeId, {String? currentUserId}) async {
    final response = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .eq('id', recipeId)
        .single();

    final recipe = _recipeFromSupabaseJson(response);

    // Fetch images from recipe_images table
    final imageUrls = await getRecipeImages(recipeId);

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
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        isFavorite: favorite != null,
        userRating: rating != null ? (rating['rating'] as int) : null,
        creator: recipe.creator,
      );
    }

    // Return recipe with images for non-authenticated users
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
  }

  Future<List<String>> getRecipeImages(String recipeId) async {
    final response = await _supabase
        .from('recipe_images')
        .select('image_url, is_primary')
        .eq('recipe_id', recipeId)
        .order('is_primary', ascending: false)
        .order('order');

    // Sort to ensure primary images are first
    final sortedResponse = (response as List).map((json) => {
      'image_url': json['image_url'] as String,
      'is_primary': json['is_primary'] as bool? ?? false,
    }).toList();
    
    sortedResponse.sort((a, b) {
      // Primary images first
      if (a['is_primary'] == true && b['is_primary'] != true) return -1;
      if (a['is_primary'] != true && b['is_primary'] == true) return 1;
      return 0;
    });

    return sortedResponse
        .map((json) => json['image_url'] as String)
        .toList();
  }

  Future<Map<String, bool>> getRecipeImagePrimaryStatus(String recipeId) async {
    final response = await _supabase
        .from('recipe_images')
        .select('image_url, is_primary')
        .eq('recipe_id', recipeId);

    final Map<String, bool> primaryStatus = {};
    for (var image in (response as List)) {
      primaryStatus[image['image_url'] as String] = image['is_primary'] as bool? ?? false;
    }
    return primaryStatus;
  }

  Future<void> setPrimaryImage(String recipeId, String imageUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify recipe exists and user is owner
    final recipe = await getRecipeById(recipeId);
    if (recipe == null) throw Exception('Recipe not found');
    if (recipe.userId != userId) throw Exception('Unauthorized: Only recipe owner can set primary image');

    // First, unset all primary flags for this recipe
    await _supabase
        .from('recipe_images')
        .update({'is_primary': false})
        .eq('recipe_id', recipeId);

    // Then set the selected image as primary
    await _supabase
        .from('recipe_images')
        .update({'is_primary': true})
        .eq('recipe_id', recipeId)
        .eq('image_url', imageUrl);
  }

  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Ensure user exists in users table
    await _ensureUserExists(userId);

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

  /// Adds an image to an existing recipe (anyone can add images)
  Future<String> addRecipeImage(String recipeId, String imageUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify recipe exists
    final recipe = await getRecipeById(recipeId);
    if (recipe == null) throw Exception('Recipe not found');

    // Get current image count to determine order
    final existingImages = await _supabase
        .from('recipe_images')
        .select('order')
        .eq('recipe_id', recipeId)
        .order('order', ascending: false)
        .limit(1);

    final nextOrder = existingImages.isNotEmpty && (existingImages.first['order'] as int?) != null
        ? (existingImages.first['order'] as int) + 1
        : 0;

    // Insert image record
    await _supabase.from('recipe_images').insert({
      'recipe_id': recipeId,
      'image_url': imageUrl,
      'is_primary': nextOrder == 0, // First image is primary
      'order': nextOrder,
    });

    return imageUrl;
  }

  Future<void> deleteRecipeImage(String recipeId, String imageUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify recipe exists and user is owner
    final recipe = await getRecipeById(recipeId);
    if (recipe == null) throw Exception('Recipe not found');
    if (recipe.userId != userId) throw Exception('Unauthorized: Only recipe owner can delete images');

    // Delete image record
    await _supabase
        .from('recipe_images')
        .delete()
        .eq('recipe_id', recipeId)
        .eq('image_url', imageUrl);

    // Extract file path from URL and delete from storage
    try {
      // Parse the storage URL to get the file path
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // Find 'recipe-images' in the path and get everything after it
      final recipeImagesIndex = pathSegments.indexWhere((s) => s == 'recipe-images');
      if (recipeImagesIndex != -1 && recipeImagesIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(recipeImagesIndex + 1).join('/');
        await _supabase.storage.from('recipe-images').remove([filePath]);
      }
    } catch (e) {
      // Log error but don't fail - the database record is already deleted
      print('Warning: Failed to delete image from storage: $e');
    }
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

    final recipesResponse = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .inFilter('id', recipeIds);

    final recipes = (recipesResponse as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();

    // Fetch images for all recipes in batch
    if (recipes.isNotEmpty) {
      final imagesResponse = await _supabase
          .from('recipe_images')
          .select('recipe_id, image_url, is_primary')
          .inFilter('recipe_id', recipeIds)
          .order('is_primary', ascending: false)
          .order('order');

      // Group images by recipe_id, ensuring primary images are first
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

      // Sort each recipe's images to ensure primary comes first
      final Map<String, List<String>> imagesMap = {};
      imagesMapRaw.forEach((recipeId, images) {
        images.sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (a['is_primary'] != true && b['is_primary'] == true) return 1;
          return 0;
        });
        imagesMap[recipeId] = images.map((img) => img['image_url'] as String).toList();
      });

      // Update recipes with their images
      return recipes.map((recipe) {
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
    }

    return recipes;
  }

  Future<List<RecipeModel>> searchRecipes(String query) async {
    final response = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .or('title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(50);

    final recipes = (response as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();

    // Fetch images for all recipes in batch
    if (recipes.isNotEmpty) {
      final recipeIds = recipes.map((r) => r.id).toList();
      final imagesResponse = await _supabase
          .from('recipe_images')
          .select('recipe_id, image_url, is_primary')
          .inFilter('recipe_id', recipeIds)
          .order('is_primary', ascending: false)
          .order('order');

      // Group images by recipe_id, ensuring primary images are first
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

      // Sort each recipe's images to ensure primary comes first
      final Map<String, List<String>> imagesMap = {};
      imagesMapRaw.forEach((recipeId, images) {
        images.sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (a['is_primary'] != true && b['is_primary'] == true) return 1;
          return 0;
        });
        imagesMap[recipeId] = images.map((img) => img['image_url'] as String).toList();
      });

      // Update recipes with their images
      return recipes.map((recipe) {
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
    }

    return recipes;
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
      // Generate unique username from email
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
}
