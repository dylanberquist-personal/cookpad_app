class ShoppingListModel {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShoppingListItemModel> items;

  ShoppingListModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => ShoppingListItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ShoppingListItemModel {
  final String id;
  final String shoppingListId;
  final String itemName;
  final String? quantity;
  final String? category;
  final bool isChecked;
  final DateTime createdAt;

  ShoppingListItemModel({
    required this.id,
    required this.shoppingListId,
    required this.itemName,
    this.quantity,
    this.category,
    this.isChecked = false,
    required this.createdAt,
  });

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemModel(
      id: json['id'] as String,
      shoppingListId: json['shopping_list_id'] as String,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as String?,
      category: json['category'] as String?,
      isChecked: json['is_checked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'item_name': itemName,
      'quantity': quantity,
      'category': category,
      'is_checked': isChecked,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
