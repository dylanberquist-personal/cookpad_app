class CommentModel {
  final String id;
  final String userId;
  final String recipeId;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? username;
  final String? profilePictureUrl;
  final bool? isFavorite; // Computed field

  CommentModel({
    required this.id,
    required this.userId,
    required this.recipeId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.profilePictureUrl,
    this.isFavorite,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recipeId: json['recipe_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: userData?['username'] as String?,
      profilePictureUrl: userData?['profile_picture_url'] as String?,
      isFavorite: json['is_favorite'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_id': recipeId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
