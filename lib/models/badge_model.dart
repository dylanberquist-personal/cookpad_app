class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String tier; // bronze, silver, gold, platinum
  final String requirementType;
  final double requirementValue;
  final DateTime createdAt;
  final DateTime? awardedAt; // null if just badge definition, populated if user badge

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.requirementType,
    required this.requirementValue,
    required this.createdAt,
    this.awardedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      tier: json['tier'] as String,
      requirementType: json['requirement_type'] as String,
      requirementValue: (json['requirement_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      awardedAt: json['awarded_at'] != null
          ? DateTime.parse(json['awarded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'created_at': createdAt.toIso8601String(),
      if (awardedAt != null) 'awarded_at': awardedAt!.toIso8601String(),
    };
  }

  // Get tier color for UI
  String get tierColor {
    switch (tier) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#808080';
    }
  }

  // Get tier display name
  String get tierDisplayName {
    return tier[0].toUpperCase() + tier.substring(1);
  }
}

