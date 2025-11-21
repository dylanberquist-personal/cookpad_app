import 'package:flutter/material.dart';
import 'user_model.dart';

enum NotificationType {
  newFollower,
  recipeFavorited,
  recipeRated,
  comment,
  remix,
  recipeImageAdded,
  badgeEarned,
  collectionShared,
  recipeShared,
  pantrySyncInvite,
  shoppingListSyncInvite,
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
      case NotificationType.badgeEarned:
        return 'badge_earned';
      case NotificationType.collectionShared:
        return 'collection_shared';
      case NotificationType.recipeShared:
        return 'recipe_shared';
      case NotificationType.pantrySyncInvite:
        return 'pantry_sync_invite';
      case NotificationType.shoppingListSyncInvite:
        return 'shopping_list_sync_invite';
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
      case 'badge_earned':
        return NotificationType.badgeEarned;
      case 'collection_shared':
        return NotificationType.collectionShared;
      case 'recipe_shared':
        return NotificationType.recipeShared;
      case 'pantry_sync_invite':
        return NotificationType.pantrySyncInvite;
      case 'shopping_list_sync_invite':
        return NotificationType.shoppingListSyncInvite;
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
      case NotificationType.badgeEarned:
        return 'Badge Earned';
      case NotificationType.collectionShared:
        return 'Collection Shared';
      case NotificationType.recipeShared:
        return 'Recipe Shared';
      case NotificationType.pantrySyncInvite:
        return 'Pantry Sync Invite';
      case NotificationType.shoppingListSyncInvite:
        return 'Shopping List Sync Invite';
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
      case NotificationType.badgeEarned:
        return Icons.military_tech;
      case NotificationType.collectionShared:
        return Icons.folder_shared;
      case NotificationType.recipeShared:
        return Icons.share;
      case NotificationType.pantrySyncInvite:
        return Icons.kitchen;
      case NotificationType.shoppingListSyncInvite:
        return Icons.shopping_cart;
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
  
  // Badge-specific data
  final String? badgeId;
  final String? badgeName;
  final String? badgeIcon;
  final String? badgeDescription;
  
  // Sharing-specific data
  final String? collectionId;
  final String? collectionName;
  final String? sharedCollectionId;
  
  // Sync-specific data
  final String? shoppingListId;
  final String? shoppingListName;
  final String? syncedPantryId;
  final String? syncedShoppingListId;
  
  // Custom message from database (used for badges)
  final String? customMessage;

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
    this.badgeId,
    this.badgeName,
    this.badgeIcon,
    this.badgeDescription,
    this.collectionId,
    this.collectionName,
    this.sharedCollectionId,
    this.shoppingListId,
    this.shoppingListName,
    this.syncedPantryId,
    this.syncedShoppingListId,
    this.customMessage,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse badge data from JSONB 'data' field
    String? badgeId;
    String? badgeName;
    String? badgeIcon;
    String? badgeDescription;
    String? collectionId;
    String? sharedCollectionId;
    String? shoppingListId;
    String? shoppingListName;
    String? syncedPantryId;
    String? syncedShoppingListId;
    
    if (json['data'] != null && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;
      badgeId = data['badge_id'] as String?;
      badgeName = data['badge_name'] as String?;
      badgeIcon = data['badge_icon'] as String?;
      badgeDescription = data['badge_description'] as String?;
      collectionId = data['collection_id'] as String?;
      sharedCollectionId = data['shared_collection_id'] as String?;
      shoppingListId = data['shopping_list_id'] as String?;
      shoppingListName = data['shopping_list_name'] as String?;
      syncedPantryId = data['synced_pantry_id'] as String?;
      syncedShoppingListId = data['synced_shopping_list_id'] as String?;
    }
    
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
      badgeId: badgeId,
      badgeName: badgeName,
      badgeIcon: badgeIcon,
      badgeDescription: badgeDescription,
      collectionId: collectionId,
      collectionName: json['collection_name'] as String?,
      sharedCollectionId: sharedCollectionId,
      shoppingListId: shoppingListId,
      shoppingListName: shoppingListName ?? json['shopping_list_name'] as String?,
      syncedPantryId: syncedPantryId,
      syncedShoppingListId: syncedShoppingListId,
      customMessage: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'actor_id': actorId,
      'recipe_id': recipeId,
      'comment_id': commentId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'message': customMessage,
    };
    
    // Add badge data if present
    if (badgeId != null || badgeName != null || badgeIcon != null || badgeDescription != null) {
      json['data'] = {
        if (badgeId != null) 'badge_id': badgeId,
        if (badgeName != null) 'badge_name': badgeName,
        if (badgeIcon != null) 'badge_icon': badgeIcon,
        if (badgeDescription != null) 'badge_description': badgeDescription,
      };
    }
    
    return json;
  }

  String get message {
    final actorName = actor?.username ?? actor?.displayName ?? 'A user';
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
      case NotificationType.badgeEarned:
        // Use custom message from database if available, otherwise build from badge data
        if (customMessage != null && customMessage!.isNotEmpty) {
          return customMessage!;
        }
        if (badgeName != null) {
          return '${badgeIcon ?? '🎖️'} Congratulations! You earned the "$badgeName" badge!';
        }
        return 'Congratulations! You earned a new badge!';
      case NotificationType.collectionShared:
        if (collectionName != null) {
          return '$actorName shared a collection with you: $collectionName';
        }
        return '$actorName shared a collection with you';
      case NotificationType.recipeShared:
        return '$actorName sent you a recipe${recipeTitle != null ? ": $recipeTitle" : ""}';
      case NotificationType.pantrySyncInvite:
        return '$actorName invited you to sync Pantries';
      case NotificationType.shoppingListSyncInvite:
        if (shoppingListName != null) {
          return '$actorName invited you to sync shopping list: $shoppingListName';
        }
        return '$actorName invited you to sync a shopping list';
    }
  }
  
  // Get a detailed message that includes badge description
  String get detailedMessage {
    if (type == NotificationType.badgeEarned && badgeDescription != null) {
      return badgeDescription!;
    }
    return '';
  }
}
