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
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      return int.parse(value.toString());
    }
    
    // Helper function to safely convert to double
    double safeDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.parse(value.toString());
    }
    
    // Helper function to convert map values to double
    Map<String, double>? convertMap(Map<dynamic, dynamic>? map) {
      if (map == null) return null;
      return map.map((key, value) => MapEntry(
        key.toString(),
        safeDouble(value),
      ));
    }
    
    return NutritionModel(
      caloriesPerServing: safeInt(json['calories_per_serving']),
      protein: safeDouble(json['protein']),
      carbohydrates: safeDouble(json['carbohydrates']),
      fats: safeDouble(json['fats']),
      fiber: json['fiber'] != null ? safeDouble(json['fiber']) : null,
      sugar: json['sugar'] != null ? safeDouble(json['sugar']) : null,
      sodium: json['sodium'] != null ? safeDouble(json['sodium']) : null,
      vitamins: json['vitamins'] != null
          ? convertMap(json['vitamins'] as Map?)
          : null,
      minerals: json['minerals'] != null
          ? convertMap(json['minerals'] as Map?)
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
