class NutritionModel {
  final int caloriesPerServing;
  final double protein; // grams
  final double carbohydrates; // grams
  final double fats; // grams
  final double? fiber; // grams
  final double? sugar; // grams
  final double? sodium; // mg
  final Map<String, double>? vitamins; // key vitamins
  final Map<String, double>? minerals; // key minerals
  final String? servingSize;

  NutritionModel({
    required this.caloriesPerServing,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    this.fiber,
    this.sugar,
    this.sodium,
    this.vitamins,
    this.minerals,
    this.servingSize,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      caloriesPerServing: json['calories_per_serving'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      sugar: json['sugar'] != null ? (json['sugar'] as num).toDouble() : null,
      sodium: json['sodium'] != null ? (json['sodium'] as num).toDouble() : null,
      vitamins: json['vitamins'] != null
          ? Map<String, double>.from(json['vitamins'] as Map)
          : null,
      minerals: json['minerals'] != null
          ? Map<String, double>.from(json['minerals'] as Map)
          : null,
      servingSize: json['serving_size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories_per_serving': caloriesPerServing,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamins': vitamins,
      'minerals': minerals,
      'serving_size': servingSize,
    };
  }
}
