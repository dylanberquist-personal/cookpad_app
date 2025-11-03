class PantryItemModel {
  final String id;
  final String userId;
  final String ingredientName;
  final String? category; // produce, dairy, proteins, grains, spices, etc.
  final String? quantity;
  final bool isLowStock;
  final DateTime addedAt;
  final DateTime updatedAt;

  PantryItemModel({
    required this.id,
    required this.userId,
    required this.ingredientName,
    this.category,
    this.quantity,
    this.isLowStock = false,
    required this.addedAt,
    required this.updatedAt,
  });

  factory PantryItemModel.fromJson(Map<String, dynamic> json) {
    return PantryItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ingredientName: json['ingredient_name'] as String,
      category: json['category'] as String?,
      quantity: json['quantity'] as String?,
      isLowStock: json['is_low_stock'] as bool? ?? false,
      addedAt: DateTime.parse(json['added_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ingredient_name': ingredientName,
      'category': category,
      'quantity': quantity,
      'is_low_stock': isLowStock,
      'added_at': addedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
