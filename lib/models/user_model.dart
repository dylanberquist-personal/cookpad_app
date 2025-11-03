class UserModel {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final double chefScore;
  final String skillLevel; // beginner, intermediate, advanced
  final List<String> dietaryRestrictions;
  final List<String>? cuisinePreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.chefScore = 0.0,
    this.skillLevel = 'beginner',
    this.dietaryRestrictions = const [],
    this.cuisinePreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      chefScore: (json['chef_score'] as num?)?.toDouble() ?? 0.0,
      skillLevel: json['skill_level'] as String? ?? 'beginner',
      dietaryRestrictions: (json['dietary_restrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cuisinePreferences: (json['cuisine_preferences'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'chef_score': chefScore,
      'skill_level': skillLevel,
      'dietary_restrictions': dietaryRestrictions,
      'cuisine_preferences': cuisinePreferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
