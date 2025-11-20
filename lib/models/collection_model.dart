class CollectionModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isPublic;
  final String color; // Hex color code for the collection card
  final DateTime createdAt;
  final DateTime updatedAt;
  final int recipeCount; // computed
  final bool isShared; // Whether this collection was shared with the current user
  final String? sharedCollectionId; // ID of the shared_collections record if shared

  CollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isPublic = false,
    this.color = '#FF6B6B', // Default coral red color
    required this.createdAt,
    required this.updatedAt,
    this.recipeCount = 0,
    this.isShared = false,
    this.sharedCollectionId,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json, {bool isShared = false, String? sharedCollectionId}) {
    return CollectionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      color: json['color'] as String? ?? '#FF6B6B',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      recipeCount: json['recipe_count'] as int? ?? 0,
      isShared: isShared,
      sharedCollectionId: sharedCollectionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'is_public': isPublic,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
