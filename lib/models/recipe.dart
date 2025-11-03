class Recipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<Ingredient> ingredients;
  final List<Step> steps;
  final int cookingTime; // in minutes
  final int servings;
  final String author;
  final DateTime createdAt;
  final int likes;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.cookingTime,
    required this.servings,
    required this.author,
    required this.createdAt,
    this.likes = 0,
    this.isFavorite = false,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<Ingredient>? ingredients,
    List<Step>? steps,
    int? cookingTime,
    int? servings,
    String? author,
    DateTime? createdAt,
    int? likes,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'cookingTime': cookingTime,
      'servings': servings,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'isFavorite': isFavorite,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      steps: (json['steps'] as List).map((s) => Step.fromJson(s)).toList(),
      cookingTime: json['cookingTime'] as int,
      servings: json['servings'] as int,
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class Ingredient {
  final String name;
  final String quantity;
  final String? unit;

  Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String?,
    );
  }
}

class Step {
  final int stepNumber;
  final String instruction;
  final String? imageUrl;

  Step({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'imageUrl': imageUrl,
    };
  }

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      stepNumber: json['stepNumber'] as int,
      instruction: json['instruction'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
