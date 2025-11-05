import 'package:flutter/material.dart';
import 'user_model.dart';

enum NotificationType {
  newFollower,
  recipeFavorited,
  recipeRated,
  comment,
  remix,
  recipeImageAdded,
}

extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.newFollower:
        return 'new_follower';
      case NotificationType.recipeFavorited:
        return 'recipe_favorited';
      case NotificationType.recipeRated:
        return 'recipe_rated';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.remix:
        return 'remix';
      case NotificationType.recipeImageAdded:
        return 'recipe_image_added';
    }
  }

  static NotificationType fromString(String type) {
    switch (type) {
      case 'new_follower':
        return NotificationType.newFollower;
      case 'recipe_favorited':
        return NotificationType.recipeFavorited;
      case 'recipe_rated':
        return NotificationType.recipeRated;
      case 'comment':
        return NotificationType.comment;
      case 'remix':
        return NotificationType.remix;
      case 'recipe_image_added':
        return NotificationType.recipeImageAdded;
      default:
        return NotificationType.newFollower;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.newFollower:
        return 'New Follower';
      case NotificationType.recipeFavorited:
        return 'Recipe Favorited';
      case NotificationType.recipeRated:
        return 'Recipe Rated';
      case NotificationType.comment:
        return 'New Comment';
      case NotificationType.remix:
        return 'Recipe Remixed';
      case NotificationType.recipeImageAdded:
        return 'Image Added';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.recipeFavorited:
        return Icons.favorite;
      case NotificationType.recipeRated:
        return Icons.star;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.remix:
        return Icons.auto_fix_high;
      case NotificationType.recipeImageAdded:
        return Icons.add_photo_alternate;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String? actorId;
  final String? recipeId;
  final String? commentId;
  final bool isRead;
  final DateTime createdAt;

  // Related data (fetched separately)
  final UserModel? actor;
  final String? recipeTitle;
  final String? commentContent;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.actorId,
    this.recipeId,
    this.commentId,
    this.isRead = false,
    required this.createdAt,
    this.actor,
    this.recipeTitle,
    this.commentContent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      actorId: json['actor_id'] as String?,
      recipeId: json['recipe_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actor: json['actor'] != null
          ? UserModel.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
      recipeTitle: json['recipe_title'] as String?,
      commentContent: json['comment_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'actor_id': actorId,
      'recipe_id': recipeId,
      'comment_id': commentId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get message {
    final actorName = actor?.username ?? actor?.displayName ?? 'Someone';
    switch (type) {
      case NotificationType.newFollower:
        return '$actorName started following you';
      case NotificationType.recipeFavorited:
        return '$actorName favorited your recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
      case NotificationType.recipeRated:
        return '$actorName rated your recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
      case NotificationType.comment:
        return '$actorName commented on your recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
      case NotificationType.remix:
        return '$actorName remixed your recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
      case NotificationType.recipeImageAdded:
        return '$actorName added an image to your recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
    }
  }
}

