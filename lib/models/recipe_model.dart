import 'nutrition_model.dart';
import 'user_model.dart';

enum DifficultyLevel { easy, medium, hard }

enum MealType { breakfast, lunch, dinner, snack, dessert }

enum SourceType { ai, photo, url, manual }

class RecipeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<IngredientModel> ingredients;
  final List<InstructionStepModel> instructions;
  final int prepTime; // minutes
  final int cookTime; // minutes
  final int totalTime; // minutes
  final int servings;
  final DifficultyLevel difficultyLevel;
  final String? cuisineType;
  final MealType mealType;
  final NutritionModel? nutrition;
  final List<String> tags;
  final SourceType sourceType;
  final String? sourceUrl;
  final bool isPublic;
  final double averageRating;
  final int ratingCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed/related fields (not in DB)
  final List<String>? imageUrls;
  final bool? isFavorite;
  final int? userRating;
  final UserModel? creator;

  RecipeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.difficultyLevel,
    this.cuisineType,
    required this.mealType,
    this.nutrition,
    this.tags = const [],
    required this.sourceType,
    this.sourceUrl,
    this.isPublic = true,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls,
    this.isFavorite,
    this.userRating,
    this.creator,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((i) => IngredientModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((i) =>
              InstructionStepModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      prepTime: json['prep_time'] as int,
      cookTime: json['cook_time'] as int,
      totalTime: json['total_time'] as int,
      servings: json['servings'] as int,
      difficultyLevel: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty_level'],
        orElse: () => DifficultyLevel.easy,
      ),
      cuisineType: json['cuisine_type'] as String?,
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['meal_type'],
        orElse: () => MealType.dinner,
      ),
      nutrition: json['nutrition'] != null
          ? NutritionModel.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sourceType: SourceType.values.firstWhere(
        (e) => e.name == json['source_type'],
        orElse: () => SourceType.manual,
      ),
      sourceUrl: json['source_url'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      imageUrls: (json['image_urls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isFavorite: json['is_favorite'] as bool?,
      userRating: json['user_rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions.map((i) => i.toJson()).toList(),
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime,
      'servings': servings,
      'difficulty_level': difficultyLevel.name,
      'cuisine_type': cuisineType,
      'meal_type': mealType.name,
      'nutrition': nutrition?.toJson(),
      'tags': tags,
      'source_type': sourceType.name,
      'source_url': sourceUrl,
      'is_public': isPublic,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'favorite_count': favoriteCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class IngredientModel {
  final String name;
  final String quantity;
  final String? unit;
  final String? category; // produce, dairy, proteins, grains, spices, etc.

  IngredientModel({
    required this.name,
    required this.quantity,
    this.unit,
    this.category,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    };
  }
}

class InstructionStepModel {
  final int stepNumber;
  final String instruction;
  final String? imageUrl;

  InstructionStepModel({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
  });

  factory InstructionStepModel.fromJson(Map<String, dynamic> json) {
    return InstructionStepModel(
      stepNumber: json['step_number'] as int,
      instruction: json['instruction'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'instruction': instruction,
      'image_url': imageUrl,
    };
  }
}
