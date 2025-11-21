import '../config/supabase_config.dart';

enum ReportType {
  image,
  titleDescriptionIngredientsInstructions,
  creatorProfile,
  comment,
}

class ReportService {
  final _supabase = SupabaseConfig.client;

  /// Report a recipe
  Future<void> reportRecipe({
    required String recipeId,
    required ReportType reportType,
    String? comment,
    String? commentId, // For reporting specific comments
    String? imageUrl, // For reporting specific images
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get recipe to find the creator
    final recipe = await _supabase
        .from('recipes')
        .select('user_id')
        .eq('id', recipeId)
        .single();

    final creatorId = recipe['user_id'] as String;

    // Convert enum to database value
    String reportTypeValue;
    switch (reportType) {
      case ReportType.image:
        reportTypeValue = 'Image';
        break;
      case ReportType.titleDescriptionIngredientsInstructions:
        reportTypeValue = 'Title/Description/Ingredients/Instructions';
        break;
      case ReportType.creatorProfile:
        reportTypeValue = 'Creator profile';
        break;
      case ReportType.comment:
        reportTypeValue = 'Comment';
        break;
    }

    // Create report
    final reportData = {
      'reporter_id': userId,
      'reported_recipe_id': recipeId,
      'reported_user_id': creatorId,
      'report_type': reportTypeValue,
      'comment': comment?.trim(),
      'status': 'pending',
    };

    // Add specific comment or image if provided
    if (commentId != null && reportType == ReportType.comment) {
      reportData['reported_comment_id'] = commentId;
    }
    if (imageUrl != null && reportType == ReportType.image) {
      reportData['reported_image_url'] = imageUrl;
    }

    await _supabase.from('user_reports').insert(reportData);
  }

  /// Report a comment
  Future<void> reportComment({
    required String commentId,
    required ReportType reportType,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get comment to find the creator and recipe
    final commentData = await _supabase
        .from('comments')
        .select('user_id, recipe_id')
        .eq('id', commentId)
        .single();

    final commentCreatorId = commentData['user_id'] as String;
    final recipeId = commentData['recipe_id'] as String;

    // Convert enum to database value
    String reportTypeValue;
    switch (reportType) {
      case ReportType.image:
        reportTypeValue = 'Image';
        break;
      case ReportType.titleDescriptionIngredientsInstructions:
        reportTypeValue = 'Title/Description/Ingredients/Instructions';
        break;
      case ReportType.creatorProfile:
        reportTypeValue = 'Creator profile';
        break;
      case ReportType.comment:
        reportTypeValue = 'Comment';
        break;
    }

    // Create report
    await _supabase.from('user_reports').insert({
      'reporter_id': userId,
      'reported_comment_id': commentId,
      'reported_user_id': commentCreatorId,
      'reported_recipe_id': recipeId,
      'report_type': reportTypeValue,
      'comment': comment?.trim(),
      'status': 'pending',
    });
  }
}

