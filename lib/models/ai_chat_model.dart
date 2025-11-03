class AiChatSessionModel {
  final String id;
  final String userId;
  final String? recipeId; // null until saved
  final List<ChatMessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiChatSessionModel({
    required this.id,
    required this.userId,
    this.recipeId,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiChatSessionModel.fromJson(Map<String, dynamic> json) {
    return AiChatSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recipeId: json['recipe_id'] as String?,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_id': recipeId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
