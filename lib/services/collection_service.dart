import '../config/supabase_config.dart';
import '../models/collection_model.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';

class CollectionService {
  final _supabase = SupabaseConfig.client;

  /// Get all collections for a user (both public and private if owner)
  Future<List<CollectionModel>> getUserCollections(String userId, {bool? isPublic}) async {
    final query = _supabase
        .from('collections')
        .select()
        .eq('user_id', userId);

    final filteredQuery = isPublic != null
        ? query.eq('is_public', isPublic)
        : query;

    final response = await filteredQuery.order('created_at', ascending: false);

    final collections = (response as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();

    // Get recipe counts for each collection
    final collectionsWithCounts = <CollectionModel>[];
    for (var collection in collections) {
      final count = await _getRecipeCount(collection.id);
      collectionsWithCounts.add(CollectionModel(
        id: collection.id,
        userId: collection.userId,
        name: collection.name,
        description: collection.description,
        isPublic: collection.isPublic,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
        recipeCount: count,
      ));
    }

    return collectionsWithCounts;
  }

  /// Get public collections for a user
  Future<List<CollectionModel>> getPublicCollections(String userId) async {
    return getUserCollections(userId, isPublic: true);
  }

  /// Get a collection by ID
  Future<CollectionModel?> getCollectionById(String collectionId) async {
    final response = await _supabase
        .from('collections')
        .select()
        .eq('id', collectionId)
        .maybeSingle();

    if (response == null) return null;

    final collection = CollectionModel.fromJson(response);
    final count = await _getRecipeCount(collectionId);

    return CollectionModel(
      id: collection.id,
      userId: collection.userId,
      name: collection.name,
      description: collection.description,
      isPublic: collection.isPublic,
      createdAt: collection.createdAt,
      updatedAt: collection.updatedAt,
      recipeCount: count,
    );
  }

  /// Create a new collection
  Future<CollectionModel> createCollection({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('collections')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'is_public': isPublic,
        })
        .select()
        .single();

    return CollectionModel.fromJson(response);
  }

  /// Update a collection
  Future<CollectionModel> updateCollection({
    required String collectionId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership
    final collection = await getCollectionById(collectionId);
    if (collection == null) throw Exception('Collection not found');
    if (collection.userId != userId) throw Exception('Unauthorized');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (isPublic != null) updateData['is_public'] = isPublic;

    await _supabase
        .from('collections')
        .update(updateData)
        .eq('id', collectionId);

    final updated = await getCollectionById(collectionId);
    return updated ?? collection;
  }

  /// Delete a collection
  Future<void> deleteCollection(String collectionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership
    final collection = await getCollectionById(collectionId);
    if (collection == null) throw Exception('Collection not found');
    if (collection.userId != userId) throw Exception('Unauthorized');

    await _supabase.from('collections').delete().eq('id', collectionId);
  }

  /// Get recipes in a collection
  Future<List<RecipeModel>> getCollectionRecipes(String collectionId) async {
    // Get recipe IDs from collection_recipes
    final response = await _supabase
        .from('collection_recipes')
        .select('recipe_id')
        .eq('collection_id', collectionId)
        .order('added_at', ascending: false);

    final recipeIds = (response as List)
        .map((json) => json['recipe_id'] as String)
        .toList();

    if (recipeIds.isEmpty) return [];

    // Fetch recipes directly from Supabase to avoid circular dependency
    final recipesResponse = await _supabase
        .from('recipes')
        .select('*, user:users!user_id(*)')
        .inFilter('id', recipeIds);

    final recipes = (recipesResponse as List)
        .map((json) => _recipeFromSupabaseJson(json))
        .toList();

    // Fetch images for all recipes
    if (recipes.isNotEmpty) {
      final imagesResponse = await _supabase
          .from('recipe_images')
          .select('recipe_id, image_url, is_primary')
          .inFilter('recipe_id', recipeIds)
          .order('is_primary', ascending: false)
          .order('order');

      // Group images by recipe_id
      final Map<String, List<String>> imagesMap = {};
      for (var image in (imagesResponse as List)) {
        final recipeId = image['recipe_id'] as String;
        if (!imagesMap.containsKey(recipeId)) {
          imagesMap[recipeId] = [];
        }
        imagesMap[recipeId]!.add(image['image_url'] as String);
      }

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

  /// Add a recipe to a collection
  Future<void> addRecipeToCollection(String collectionId, String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify collection ownership
    final collection = await getCollectionById(collectionId);
    if (collection == null) throw Exception('Collection not found');
    if (collection.userId != userId) throw Exception('Unauthorized');

    // Check if recipe already in collection
    final existing = await _supabase
        .from('collection_recipes')
        .select()
        .eq('collection_id', collectionId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Recipe already in collection');
    }

    await _supabase.from('collection_recipes').insert({
      'collection_id': collectionId,
      'recipe_id': recipeId,
    });
  }

  /// Remove a recipe from a collection
  Future<void> removeRecipeFromCollection(String collectionId, String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify collection ownership
    final collection = await getCollectionById(collectionId);
    if (collection == null) throw Exception('Collection not found');
    if (collection.userId != userId) throw Exception('Unauthorized');

    await _supabase
        .from('collection_recipes')
        .delete()
        .eq('collection_id', collectionId)
        .eq('recipe_id', recipeId);
  }

  /// Get recipe count for a collection
  Future<int> _getRecipeCount(String collectionId) async {
    final response = await _supabase
        .from('collection_recipes')
        .select()
        .eq('collection_id', collectionId);

    return (response as List).length;
  }

  /// Check if a recipe is in a collection
  Future<bool> isRecipeInCollection(String collectionId, String recipeId) async {
    final response = await _supabase
        .from('collection_recipes')
        .select()
        .eq('collection_id', collectionId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    return response != null;
  }

  /// Get or create the default "Favorites" collection for the current user
  Future<CollectionModel> getOrCreateFavoritesCollection() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Try to find existing "Favorites" collection
    final response = await _supabase
        .from('collections')
        .select()
        .eq('user_id', userId)
        .eq('name', 'Favorites')
        .maybeSingle();

    if (response != null) {
      final collection = CollectionModel.fromJson(response);
      final count = await _getRecipeCount(collection.id);
      return CollectionModel(
        id: collection.id,
        userId: collection.userId,
        name: collection.name,
        description: collection.description,
        isPublic: collection.isPublic,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
        recipeCount: count,
      );
    }

    // Create "Favorites" collection if it doesn't exist
    final newCollection = await createCollection(
      name: 'Favorites',
      description: 'Your favorite recipes',
      isPublic: false,
    );
    return newCollection;
  }

  /// Get all collections that contain a recipe
  Future<List<CollectionModel>> getCollectionsContainingRecipe(String recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get collection IDs that contain this recipe
    final response = await _supabase
        .from('collection_recipes')
        .select('collection_id')
        .eq('recipe_id', recipeId);

    final collectionIds = (response as List)
        .map((json) => json['collection_id'] as String)
        .toList();

    if (collectionIds.isEmpty) return [];

    // Get collections (only user's own collections)
    final collectionsResponse = await _supabase
        .from('collections')
        .select()
        .eq('user_id', userId)
        .inFilter('id', collectionIds);

    final collections = (collectionsResponse as List)
        .map((json) => CollectionModel.fromJson(json))
        .toList();

    // Get recipe counts
    final collectionsWithCounts = <CollectionModel>[];
    for (var collection in collections) {
      final count = await _getRecipeCount(collection.id);
      collectionsWithCounts.add(CollectionModel(
        id: collection.id,
        userId: collection.userId,
        name: collection.name,
        description: collection.description,
        isPublic: collection.isPublic,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
        recipeCount: count,
      ));
    }

    return collectionsWithCounts;
  }
}

