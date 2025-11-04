import 'dart:io';
import 'package:flutter/material.dart' hide Step;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/recipe_model.dart';
import '../models/nutrition_model.dart';
import '../services/recipe_service_supabase.dart';
import '../services/ai_recipe_service.dart';
import '../config/supabase_config.dart';
import '../services/comment_service.dart';
import '../models/comment_model.dart';
import '../widgets/creator_profile_card.dart';
import 'main_navigation.dart';

class RecipeDetailScreenNew extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreenNew({super.key, required this.recipe});

  @override
  State<RecipeDetailScreenNew> createState() => _RecipeDetailScreenNewState();
}

class _RecipeDetailScreenNewState extends State<RecipeDetailScreenNew> {
  late RecipeModel _recipe;
  final _recipeService = RecipeServiceSupabase();
  final _commentService = CommentService();
  final _aiRecipeService = AiRecipeService();
  bool _isLoading = true;
  List<CommentModel> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  static const int _maxCommentLength = 255;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });
    
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final recipe = await _recipeService.getRecipeById(widget.recipe.id, currentUserId: userId);
    final comments = await _commentService.listComments(widget.recipe.id, currentUserId: userId);
    
    setState(() {
      _recipe = recipe ?? widget.recipe;
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    // Optimistic update - toggle immediately
    setState(() {
      _recipe = RecipeModel(
        id: _recipe.id,
        userId: _recipe.userId,
        title: _recipe.title,
        description: _recipe.description,
        ingredients: _recipe.ingredients,
        instructions: _recipe.instructions,
        prepTime: _recipe.prepTime,
        cookTime: _recipe.cookTime,
        totalTime: _recipe.totalTime,
        servings: _recipe.servings,
        difficultyLevel: _recipe.difficultyLevel,
        cuisineType: _recipe.cuisineType,
        mealType: _recipe.mealType,
        nutrition: _recipe.nutrition,
        tags: _recipe.tags,
        sourceType: _recipe.sourceType,
        sourceUrl: _recipe.sourceUrl,
        isPublic: _recipe.isPublic,
        averageRating: _recipe.averageRating,
        ratingCount: _recipe.ratingCount,
        favoriteCount: _recipe.favoriteCount + (_recipe.isFavorite == true ? -1 : 1),
        createdAt: _recipe.createdAt,
        updatedAt: _recipe.updatedAt,
        imageUrls: _recipe.imageUrls,
        isFavorite: !(_recipe.isFavorite == true),
        userRating: _recipe.userRating,
        creator: _recipe.creator,
      );
    });
    
    try {
      // Update server
    await _recipeService.toggleFavorite(_recipe.id);
    } catch (e) {
      // Revert on error
      setState(() {
        _recipe = RecipeModel(
          id: _recipe.id,
          userId: _recipe.userId,
          title: _recipe.title,
          description: _recipe.description,
          ingredients: _recipe.ingredients,
          instructions: _recipe.instructions,
          prepTime: _recipe.prepTime,
          cookTime: _recipe.cookTime,
          totalTime: _recipe.totalTime,
          servings: _recipe.servings,
          difficultyLevel: _recipe.difficultyLevel,
          cuisineType: _recipe.cuisineType,
          mealType: _recipe.mealType,
          nutrition: _recipe.nutrition,
          tags: _recipe.tags,
          sourceType: _recipe.sourceType,
          sourceUrl: _recipe.sourceUrl,
          isPublic: _recipe.isPublic,
          averageRating: _recipe.averageRating,
          ratingCount: _recipe.ratingCount,
          favoriteCount: _recipe.favoriteCount + (_recipe.isFavorite == true ? 1 : -1),
          createdAt: _recipe.createdAt,
          updatedAt: _recipe.updatedAt,
          imageUrls: _recipe.imageUrls,
          isFavorite: !(_recipe.isFavorite == true),
          userRating: _recipe.userRating,
          creator: _recipe.creator,
        );
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: $e')),
      );
    }
  }

  Future<void> _rateRecipe(int rating) async {
    await _recipeService.rateRecipe(_recipe.id, rating);
    await _loadRecipe();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  Future<void> _addImageToRecipe() async {
    try {
      final imagePicker = ImagePicker();
      // Allow multiple image selection
      final images = await imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final supabase = SupabaseConfig.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        int successCount = 0;
        for (final image in images) {
          try {
            final file = File(image.path);
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_$successCount.jpg';
            final filePath = '$userId/$fileName';

            await supabase.storage.from('recipe-images').upload(
              filePath,
              file,
            );

            final imageUrl = supabase.storage.from('recipe-images').getPublicUrl(filePath);

            // Add image to recipe
            await _recipeService.addRecipeImage(_recipe.id, imageUrl);
            successCount++;
          } catch (e) {
            print('Failed to upload image: $e');
          }
        }

        // Reload recipe to show new images
        await _loadRecipe();

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${successCount} image(s) added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload images: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _recipeService.deleteRecipeImage(_recipe.id, imageUrl);
      await _loadRecipe();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleCommentFavorite(String commentId, int index) async {
    final comment = _comments[index];
    final newFavoriteStatus = !(comment.isFavorite == true);
    
    // Optimistic update
    setState(() {
      _comments[index] = CommentModel(
        id: comment.id,
        userId: comment.userId,
        recipeId: comment.recipeId,
        parentCommentId: comment.parentCommentId,
        content: comment.content,
        createdAt: comment.createdAt,
        updatedAt: comment.updatedAt,
        username: comment.username,
        profilePictureUrl: comment.profilePictureUrl,
        isFavorite: newFavoriteStatus,
      );
    });

    try {
      await _commentService.toggleFavoriteComment(commentId);
    } catch (e) {
      // Revert on error
      setState(() {
        _comments[index] = comment;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _commentService.deleteComment(commentId);
      
      // Remove from local list
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete comment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNutritionInfo() {
    if (_recipe.nutrition == null) {
      // Show dialog asking if user wants to generate nutrition info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Nutrition Info'),
          content: const Text(
            "There's no nutrition info for this recipe. Would you like to have our AI estimate it for you?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateNutritionInfo();
              },
              child: const Text('Generate Nutrition Info'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => _NutritionInfoDialog(
          nutrition: _recipe.nutrition!,
          servings: _recipe.servings,
          recipe: _recipe,
          onRegenerate: () async {
            await _generateNutritionInfo();
          },
        ),
      );
    }
  }

  Future<void> _generateNutritionInfo({bool regenerate = false}) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(regenerate 
                ? 'Regenerating nutrition info with detailed calculation...'
                : 'Generating nutrition info...'),
          ],
        ),
      ),
    );

    try {
      // Generate or regenerate nutrition info using AI
      final nutrition = regenerate
          ? await _aiRecipeService.regenerateNutritionInfo(_recipe)
          : await _aiRecipeService.generateNutritionInfo(_recipe);
      
      // Update recipe with nutrition info
      final updatedRecipe = RecipeModel(
        id: _recipe.id,
        userId: _recipe.userId,
        title: _recipe.title,
        description: _recipe.description,
        ingredients: _recipe.ingredients,
        instructions: _recipe.instructions,
        prepTime: _recipe.prepTime,
        cookTime: _recipe.cookTime,
        totalTime: _recipe.totalTime,
        servings: _recipe.servings,
        difficultyLevel: _recipe.difficultyLevel,
        cuisineType: _recipe.cuisineType,
        mealType: _recipe.mealType,
        nutrition: nutrition,
        tags: _recipe.tags,
        sourceType: _recipe.sourceType,
        sourceUrl: _recipe.sourceUrl,
        isPublic: _recipe.isPublic,
        averageRating: _recipe.averageRating,
        ratingCount: _recipe.ratingCount,
        favoriteCount: _recipe.favoriteCount,
        createdAt: _recipe.createdAt,
        updatedAt: DateTime.now(),
        imageUrls: _recipe.imageUrls,
        isFavorite: _recipe.isFavorite,
        userRating: _recipe.userRating,
        creator: _recipe.creator,
      );

      // Save to database
      await _recipeService.updateRecipe(updatedRecipe);

      // Update local state
      setState(() {
        _recipe = updatedRecipe;
      });

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success message and nutrition dialog
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regenerate 
              ? 'Nutrition info regenerated successfully!'
              : 'Nutrition info generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Show nutrition info dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _NutritionInfoDialog(
          nutrition: nutrition,
          servings: _recipe.servings,
          recipe: _recipe,
          onRegenerate: () async {
            await _generateNutritionInfo(regenerate: true);
          },
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate nutrition info: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageGallery(int initialIndex) async {
    if (_recipe.imageUrls == null || _recipe.imageUrls!.isEmpty) return;
    
    // Fetch primary image status
    final primaryStatus = await _recipeService.getRecipeImagePrimaryStatus(_recipe.id);
    
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(
          images: List.from(_recipe.imageUrls!),
          initialIndex: initialIndex,
          recipeId: _recipe.id,
          userId: _recipe.userId,
          primaryStatus: primaryStatus,
          onDelete: _deleteImage,
          onSetPrimary: () async {
            await _loadRecipe();
          },
        ),
      ),
    ).then((_) => _loadRecipe()); // Reload recipe when returning
  }

  void _remixRecipe() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(
          initialIndex: 2,
          remixRecipe: _recipe,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (text.length > _maxCommentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment must be ${_maxCommentLength} characters or less. Current: ${text.length}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    // Get current user info for optimistic UI update
    final currentUser = await SupabaseConfig.client
        .from('users')
        .select('username, profile_picture_url')
        .eq('id', currentUserId)
        .single();
    
    // Create optimistic comment
    final optimisticComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      userId: currentUserId,
      recipeId: _recipe.id,
      content: text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      username: currentUser['username'] as String?,
      profilePictureUrl: currentUser['profile_picture_url'] as String?,
    );
    
    // Add to list immediately (optimistic update)
    setState(() {
      _comments = [..._comments, optimisticComment];
      _commentController.clear();
    });
    
    try {
      // Post comment to server
      final newComment = await _commentService.addComment(
        recipeId: _recipe.id,
        content: text,
      );
      
      // Replace optimistic comment with real one from server
      setState(() {
        _comments = _comments
            .where((c) => c.id != optimisticComment.id)
            .toList()
          ..add(newComment);
        // Sort by created_at to maintain order
        _comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
    } catch (e) {
      // Remove optimistic comment on error
      setState(() {
        _comments = _comments
            .where((c) => c.id != optimisticComment.id)
            .toList();
        _commentController.text = text; // Restore text
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _recipe.imageUrls?.isNotEmpty == true
                  ? GestureDetector(
                      onTap: () => _showImageGallery(0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(_recipe.imageUrls!.first, fit: BoxFit.cover),
                          if (_recipe.imageUrls!.length > 1)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${_recipe.imageUrls!.length - 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                    ),
            ),
            actions: [
              // Remix button (always visible)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  color: Colors.white,
                  onPressed: _remixRecipe,
                  tooltip: 'Remix Recipe',
                ),
              ),
              // Show add image button if user is authenticated (anyone can add images)
              if (SupabaseConfig.client.auth.currentUser != null)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    color: Colors.white,
                    onPressed: _addImageToRecipe,
                    tooltip: 'Add Image',
                  ),
                ),
              // Nutrition info button (always visible)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.restaurant_menu),
                  color: Colors.white,
                  onPressed: _showNutritionInfo,
                  tooltip: 'Nutrition Info',
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                icon: Icon(_recipe.isFavorite == true ? Icons.favorite : Icons.favorite_border),
                color: _recipe.isFavorite == true ? Colors.red : Colors.white,
                onPressed: _toggleFavorite,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recipe.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_recipe.description),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.access_time, size: 18),
                        label: Text('${_recipe.totalTime} min'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.people, size: 18),
                        label: Text('${_recipe.servings} servings'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.star, size: 18),
                        label: Text('${_recipe.averageRating.toStringAsFixed(1)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < (_recipe.userRating ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                            size: 40,
                        ),
                          iconSize: 40,
                        onPressed: () => _rateRecipe(index + 1),
                      );
                    }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._recipe.ingredients.map(
                    (ingredient) => ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('${ingredient.quantity}${ingredient.unit != null ? ' ${ingredient.unit}' : ''} ${ingredient.name}'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Instructions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._recipe.instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            child: Text('${step.stepNumber}'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(step.instruction)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Creator Profile Card
                  CreatorProfileCard(
                    creator: _recipe.creator,
                    userId: _recipe.creator?.id ?? _recipe.userId,
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 32),
                  const Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_comments.isEmpty)
                    Text(
                      'No comments yet. Be the first to share a tip!',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    ..._comments.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final c = entry.value;
                        final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
                        final isRecipeOwner = currentUserId != null && _recipe.userId == currentUserId;
                        final isCommentOwner = currentUserId != null && c.userId == currentUserId;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: c.profilePictureUrl != null
                                ? NetworkImage(c.profilePictureUrl!)
                                : null,
                            child: c.profilePictureUrl == null
                                ? Icon(Icons.person, color: Colors.grey[600])
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.username ?? 'Unknown User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              if (currentUserId != null)
                                IconButton(
                                  icon: Icon(
                                    c.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                    size: 22,
                                    color: c.isFavorite == true ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleCommentFavorite(c.id, index),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              if (isRecipeOwner || isCommentOwner)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                                    onPressed: () => _deleteComment(c.id),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(c.content),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(c.createdAt),
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 1,
                          maxLines: 3,
                        maxLength: _maxCommentLength,
                        onChanged: (value) {
                          setState(() {}); // Update character count
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _commentController.text.trim().isEmpty ||
                                  _commentController.text.length > _maxCommentLength
                              ? null
                              : _submitComment,
                          child: const Text('Post'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String recipeId;
  final String userId;
  final Map<String, bool> primaryStatus;
  final Function(String) onDelete;
  final VoidCallback onSetPrimary;

  const _ImageGalleryView({
    required this.images,
    required this.initialIndex,
    required this.recipeId,
    required this.userId,
    required this.primaryStatus,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  State<_ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<_ImageGalleryView> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _images;
  late Map<String, bool> _primaryStatus;
  final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
  final _recipeService = RecipeServiceSupabase();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _images = List.from(widget.images);
    _primaryStatus = Map.from(widget.primaryStatus);
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canDelete => currentUserId != null && currentUserId == widget.userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_canDelete) ...[
            // Set as primary button
            IconButton(
              icon: Icon(
                _primaryStatus[_images[_currentIndex]] == true
                    ? Icons.star
                    : Icons.star_border,
                color: _primaryStatus[_images[_currentIndex]] == true
                    ? Colors.amber
                    : Colors.white,
              ),
              onPressed: () async {
                final imageUrl = _images[_currentIndex];
                final isCurrentlyPrimary = _primaryStatus[imageUrl] == true;
                
                if (isCurrentlyPrimary) {
                  // Already primary, show message
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This is already the primary image'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  return;
                }

                try {
                  await _recipeService.setPrimaryImage(widget.recipeId, imageUrl);
                  
                  // Update local state
                  setState(() {
                    // Unset all primary flags
                    for (var url in _primaryStatus.keys) {
                      _primaryStatus[url] = false;
                    }
                    // Set current image as primary
                    _primaryStatus[imageUrl] = true;
                  });

                  // Notify parent to reload
                  widget.onSetPrimary();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Set as primary image'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to set primary image: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: _primaryStatus[_images[_currentIndex]] == true
                  ? 'Primary image'
                  : 'Set as primary',
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Image'),
                    content: const Text('Are you sure you want to delete this image?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  widget.onDelete(_images[_currentIndex]);
                  if (mounted) {
                    if (_images.length == 1) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _images.removeAt(_currentIndex);
                        if (_currentIndex >= _images.length) {
                          _currentIndex = _images.length - 1;
                        }
                        _pageController.jumpToPage(_currentIndex);
                      });
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                _images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 48),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _images.length > 1
          ? Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    final isPrimary = _primaryStatus[_images[index]] == true;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                _images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isPrimary)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                },
              ),
            )
          : null,
    );
  }
}

class _NutritionInfoDialog extends StatefulWidget {
  final NutritionModel nutrition;
  final int servings;
  final RecipeModel recipe;
  final VoidCallback onRegenerate;

  const _NutritionInfoDialog({
    required this.nutrition,
    required this.servings,
    required this.recipe,
    required this.onRegenerate,
  });

  @override
  State<_NutritionInfoDialog> createState() => _NutritionInfoDialogState();
}

enum ServingUnit { grams, ounces, custom }

class _NutritionInfoDialogState extends State<_NutritionInfoDialog> {
  final TextEditingController _customServingController = TextEditingController();
  double? _customValue;
  bool _showCustom = false;
  ServingUnit _selectedUnit = ServingUnit.grams;

  @override
  void initState() {
    super.initState();
    _determineDefaultUnit();
  }

  @override
  void dispose() {
    _customServingController.dispose();
    super.dispose();
  }

  void _determineDefaultUnit() {
    final servingSize = widget.nutrition.servingSize;
    if (servingSize != null) {
      final lower = servingSize.toLowerCase();
      if (lower.contains('oz') || lower.contains('ounce')) {
        _selectedUnit = ServingUnit.ounces;
      } else if (lower.contains('g') || lower.contains('gram')) {
        _selectedUnit = ServingUnit.grams;
      } else {
        // If it's a specific unit like "1 patty", use custom
        _selectedUnit = ServingUnit.custom;
      }
    }
  }

  void _parseCustomServing(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _customValue = null;
      });
      return;
    }
    
    final numValue = double.tryParse(input.trim());
    if (numValue == null) {
      setState(() {
        _customValue = null;
      });
      return;
    }
    
    setState(() {
      _customValue = numValue;
    });
  }

  /// Parses a fraction string like "1/8" and returns the decimal value
  double? _parseFraction(String fractionStr) {
    final fractionMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(fractionStr);
    if (fractionMatch != null) {
      final numerator = double.tryParse(fractionMatch.group(1) ?? '');
      final denominator = double.tryParse(fractionMatch.group(2) ?? '');
      if (numerator != null && denominator != null && denominator > 0) {
        return numerator / denominator;
      }
    }
    return null;
  }

  /// Estimates total recipe weight in grams from ingredients
  double? _estimateRecipeWeight() {
    if (widget.recipe.ingredients.isEmpty) return null;
    
    double totalWeight = 0;
    
    for (final ingredient in widget.recipe.ingredients) {
      final quantity = double.tryParse(ingredient.quantity.trim());
      if (quantity == null) continue;
      
      final unit = (ingredient.unit ?? '').toLowerCase();
      double weightInGrams = 0;
      
      // Convert common units to grams
      if (unit.contains('cup')) {
        // Estimate based on ingredient type
        final name = ingredient.name.toLowerCase();
        if (name.contains('flour') || name.contains('sugar')) {
          weightInGrams = quantity * 120; // 1 cup flour/sugar ≈ 120g
        } else if (name.contains('butter') || name.contains('oil')) {
          weightInGrams = quantity * 227; // 1 cup butter/oil ≈ 227g
        } else if (name.contains('milk') || name.contains('water') || name.contains('broth')) {
          weightInGrams = quantity * 240; // 1 cup liquid ≈ 240g
        } else {
          weightInGrams = quantity * 150; // Default estimate
        }
      } else if (unit.contains('tbsp') || unit.contains('tablespoon')) {
        weightInGrams = quantity * 15; // 1 tbsp ≈ 15g
      } else if (unit.contains('tsp') || unit.contains('teaspoon')) {
        weightInGrams = quantity * 5; // 1 tsp ≈ 5g
      } else if (unit.contains('oz') || unit.contains('ounce')) {
        weightInGrams = quantity * 28.35; // 1 oz = 28.35g
      } else if (unit.contains('lb') || unit.contains('pound')) {
        weightInGrams = quantity * 453.6; // 1 lb = 453.6g
      } else if (unit.contains('g') || unit.contains('gram')) {
        weightInGrams = quantity;
      } else if (unit.isEmpty || unit.contains('piece') || unit.contains('whole')) {
        // Estimate based on ingredient name
        final name = ingredient.name.toLowerCase();
        if (name.contains('egg')) {
          weightInGrams = quantity * 50; // 1 egg ≈ 50g
        } else if (name.contains('onion')) {
          weightInGrams = quantity * 150; // 1 onion ≈ 150g
        } else if (name.contains('tomato')) {
          weightInGrams = quantity * 150; // 1 tomato ≈ 150g
        } else if (name.contains('potato')) {
          weightInGrams = quantity * 200; // 1 potato ≈ 200g
        } else if (name.contains('chicken') || name.contains('beef') || name.contains('pork')) {
          // For meat, assume quantity is in pounds or estimate based on typical serving
          weightInGrams = quantity * 150; // Default estimate
        } else {
          weightInGrams = quantity * 100; // Default estimate
        }
      }
      
      totalWeight += weightInGrams;
    }
    
    return totalWeight > 0 ? totalWeight : null;
  }

  double? _getOriginalServingSizeInGrams() {
    final servingSize = widget.nutrition.servingSize;
    if (servingSize == null) return null;
    
    // Try to parse the serving size string
    // First, try to find weight in parentheses like "1 patty (200g)" or "1 slice (150g)"
    final parenMatch = RegExp(r'\((\d+\.?\d*)\s*(g|grams?|oz|ounces?)\)').firstMatch(servingSize.toLowerCase());
    if (parenMatch != null) {
      final value = double.tryParse(parenMatch.group(1) ?? '');
      final unit = parenMatch.group(2)?.toLowerCase() ?? '';
      if (value != null) {
        if (unit.contains('oz') || unit.contains('ounce')) {
          return value * 28.35; // Convert oz to grams
        } else {
          return value; // Already in grams
        }
      }
    }
    
    // Try to parse grams or ounces directly
    final servingSizeLower = servingSize.toLowerCase();
    final gramMatch = RegExp(r'(\d+\.?\d*)\s*g(?:rams?)?').firstMatch(servingSizeLower);
    final ozMatch = RegExp(r'(\d+\.?\d*)\s*oz(?:\.|ounces?)?').firstMatch(servingSizeLower);
    
    if (gramMatch != null) {
      return double.tryParse(gramMatch.group(1) ?? '');
    } else if (ozMatch != null) {
      final oz = double.tryParse(ozMatch.group(1) ?? '');
      return oz != null ? oz * 28.35 : null;
    }
    
    // Try to parse fraction (e.g., "1/8 of recipe")
    final fractionMatch = RegExp(r'(\d+/\d+)\s*of\s*recipe').firstMatch(servingSizeLower);
    if (fractionMatch != null) {
      final fraction = _parseFraction(fractionMatch.group(1) ?? '');
      if (fraction != null) {
        // Estimate total recipe weight and calculate serving weight
        final totalWeight = _estimateRecipeWeight();
        if (totalWeight != null) {
          return totalWeight * fraction;
        }
      }
    }
    
    // Try to parse any fraction in the serving size
    final anyFractionMatch = RegExp(r'(\d+/\d+)').firstMatch(servingSizeLower);
    if (anyFractionMatch != null) {
      final fraction = _parseFraction(anyFractionMatch.group(1) ?? '');
      if (fraction != null) {
        final totalWeight = _estimateRecipeWeight();
        if (totalWeight != null) {
          return totalWeight * fraction;
        }
      }
    }
    
    return null;
  }
  
  double? _getCustomValueInGrams() {
    if (_customValue == null) return null;
    
    switch (_selectedUnit) {
      case ServingUnit.grams:
        return _customValue;
      case ServingUnit.ounces:
        return _customValue! * 28.35; // Convert oz to grams
      case ServingUnit.custom:
        // For custom units, we need to calculate based on the serving size
        // If original is "1 patty" and custom is "2 patties", ratio is 2
        final originalServingGrams = _getOriginalServingSizeInGrams();
        if (originalServingGrams != null && originalServingGrams > 0) {
          // Assume the custom value is a multiplier of the original serving
          return originalServingGrams * _customValue!;
        }
        // Fallback: assume grams
        return _customValue;
    }
  }
  
  String _getUnitDisplayText() {
    switch (_selectedUnit) {
      case ServingUnit.grams:
        return 'g';
      case ServingUnit.ounces:
        return 'oz';
      case ServingUnit.custom:
        // When custom unit is selected, show "servings" instead of the custom unit name
        return 'servings';
    }
  }

  Map<String, dynamic>? _calculateCustomNutrition() {
    if (_customValue == null) return null;
    
    // For grams and ounces, we need to calculate based on weight ratio
    if (_selectedUnit == ServingUnit.grams || _selectedUnit == ServingUnit.ounces) {
      final customGrams = _getCustomValueInGrams();
      if (customGrams == null) return null;
      
      double? originalServingGrams = _getOriginalServingSizeInGrams();
      
      // If we can't parse the original serving size weight, try to estimate from fraction
      if (originalServingGrams == null || originalServingGrams == 0) {
        final servingSize = widget.nutrition.servingSize;
        if (servingSize != null) {
          final servingSizeLower = servingSize.toLowerCase();
          
          // Try to parse fraction (e.g., "1/8 of recipe" or "1 slice (1/8 of recipe)")
          final fractionMatch = RegExp(r'(\d+/\d+)\s*of\s*recipe').firstMatch(servingSizeLower);
          if (fractionMatch != null) {
            final fraction = _parseFraction(fractionMatch.group(1) ?? '');
            if (fraction != null) {
              final totalWeight = _estimateRecipeWeight();
              if (totalWeight != null) {
                originalServingGrams = totalWeight * fraction;
              }
            }
          } else {
            // Try to find any fraction
            final anyFractionMatch = RegExp(r'(\d+/\d+)').firstMatch(servingSizeLower);
            if (anyFractionMatch != null) {
              final fraction = _parseFraction(anyFractionMatch.group(1) ?? '');
              if (fraction != null) {
                final totalWeight = _estimateRecipeWeight();
                if (totalWeight != null) {
                  originalServingGrams = totalWeight * fraction;
                }
              }
            }
          }
        }
      }
      
      if (originalServingGrams == null || originalServingGrams == 0) {
        // If we still can't determine the original serving weight, return null
        return null;
      }
      
      // Calculate ratio based on weight
      final ratio = customGrams / originalServingGrams;
      return {
        'calories': (widget.nutrition.caloriesPerServing * ratio).round(),
        'protein': widget.nutrition.protein * ratio,
        'carbs': widget.nutrition.carbohydrates * ratio,
        'fats': widget.nutrition.fats * ratio,
      };
    }
    
    // For custom units (like "patty"), treat as multiplier
    // If original is "1 patty" and user enters "2", ratio is 2
    if (_selectedUnit == ServingUnit.custom) {
      final originalServingGrams = _getOriginalServingSizeInGrams();
      if (originalServingGrams != null && originalServingGrams > 0) {
        // Use weight-based calculation
        final customGrams = _getCustomValueInGrams();
        if (customGrams != null) {
          final ratio = customGrams / originalServingGrams;
          return {
            'calories': (widget.nutrition.caloriesPerServing * ratio).round(),
            'protein': widget.nutrition.protein * ratio,
            'carbs': widget.nutrition.carbohydrates * ratio,
            'fats': widget.nutrition.fats * ratio,
          };
        }
      }
      // Fallback: treat as simple multiplier
      final ratio = _customValue!;
      return {
        'calories': (widget.nutrition.caloriesPerServing * ratio).round(),
        'protein': widget.nutrition.protein * ratio,
        'carbs': widget.nutrition.carbohydrates * ratio,
        'fats': widget.nutrition.fats * ratio,
      };
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Nutrition Information'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate Nutrition Info',
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Regenerate Nutrition Info'),
                        content: const Text(
                          'This will regenerate the nutrition information using a more detailed calculation method. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                      ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Regenerate'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      Navigator.of(context).pop(); // Close nutrition dialog
                      widget.onRegenerate(); // Trigger regeneration
                    }
                  },
                  ),
                ],
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Serving Size (only show if it's not a generic "1 serving" format)
                    if (widget.nutrition.servingSize != null && 
                        !widget.nutrition.servingSize!.toLowerCase().contains('1 serving') &&
                        !widget.nutrition.servingSize!.toLowerCase().contains('per serving'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.scale, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Serving Size: ${widget.nutrition.servingSize}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Calories
                    _buildNutritionRow(
                      'Calories',
                      '${widget.nutrition.caloriesPerServing}',
                      'kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    const Divider(),
                    
                    // Macros Section
                    const Text(
                      'Macronutrients',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionRow(
                      'Protein',
                      widget.nutrition.protein.toStringAsFixed(1),
                      'g',
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                    ),
                    _buildNutritionRow(
                      'Carbohydrates',
                      widget.nutrition.carbohydrates.toStringAsFixed(1),
                      'g',
                      icon: Icons.energy_savings_leaf,
                      color: Colors.green,
                    ),
                    _buildNutritionRow(
                      'Fats',
                      widget.nutrition.fats.toStringAsFixed(1),
                      'g',
                      icon: Icons.opacity,
                      color: Colors.yellow.shade700,
                    ),
                    if (widget.nutrition.fiber != null)
                      _buildNutritionRow(
                        'Fiber',
                        widget.nutrition.fiber!.toStringAsFixed(1),
                        'g',
                        icon: Icons.eco,
                        color: Colors.brown,
                      ),
                    if (widget.nutrition.sugar != null)
                      _buildNutritionRow(
                        'Sugar',
                        widget.nutrition.sugar!.toStringAsFixed(1),
                        'g',
                        icon: Icons.cookie,
                        color: Colors.pink,
                      ),
                    if (widget.nutrition.sodium != null)
                      _buildNutritionRow(
                        'Sodium',
                        widget.nutrition.sodium!.toStringAsFixed(0),
                        'mg',
                        icon: Icons.blur_on,
                        color: Colors.grey,
                      ),
                    
                    // Micronutrients Section
                    if (widget.nutrition.vitamins != null && widget.nutrition.vitamins!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Vitamins',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...widget.nutrition.vitamins!.entries.map((entry) =>
                        _buildNutritionRow(
                          entry.key,
                          entry.value.toStringAsFixed(1),
                          getVitaminUnit(entry.key),
                          icon: Icons.medication,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                    
                    if (widget.nutrition.minerals != null && widget.nutrition.minerals!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Minerals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...widget.nutrition.minerals!.entries.map((entry) =>
                        _buildNutritionRow(
                          entry.key,
                          entry.value.toStringAsFixed(1),
                          getMineralUnit(entry.key),
                          icon: Icons.diamond,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                    
                    // Custom Serving Calculator
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCustom = !_showCustom;
                                if (!_showCustom) {
                                  _customServingController.clear();
                                  _customValue = null;
                                }
                              });
                            },
                            icon: Icon(_showCustom ? Icons.expand_less : Icons.expand_more),
                            label: Text(_showCustom ? 'Hide Calculator' : 'Custom Serving Calculator'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_showCustom) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customServingController,
                              decoration: InputDecoration(
                                labelText: 'Enter amount',
                                border: const OutlineInputBorder(),
                                suffixIcon: _customValue != null
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                _parseCustomServing(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit selector button
                          PopupMenuButton<ServingUnit>(
                            initialValue: _selectedUnit,
                            onSelected: (unit) {
                              setState(() {
                                _selectedUnit = unit;
                                // Re-parse to update calculations
                                _parseCustomServing(_customServingController.text);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_getUnitDisplayText()),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<ServingUnit>>[];
                              
                              // Always include grams and ounces
                              items.add(
                                PopupMenuItem(
                                  value: ServingUnit.grams,
                                  child: const Text('g (grams)'),
                                ),
                              );
                              items.add(
                                PopupMenuItem(
                                  value: ServingUnit.ounces,
                                  child: const Text('oz (ounces)'),
                                ),
                              );
                              
                              // Add "servings" option if serving size has a specific unit (not grams/ounces)
                              final servingSize = widget.nutrition.servingSize;
                              if (servingSize != null) {
                                final lower = servingSize.toLowerCase();
                                if (!lower.contains('g') && !lower.contains('gram') && 
                                    !lower.contains('oz') && !lower.contains('ounce')) {
                                  items.add(
                                    PopupMenuItem(
                                      value: ServingUnit.custom,
                                      child: const Text('servings'),
                                    ),
                                  );
                                }
                              }
                              
                              return items;
                            },
                          ),
                        ],
                      ),
                      
                      if (_customValue != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Custom Serving Nutrition (${_customValue!.toStringAsFixed(_customValue! % 1 == 0 ? 0 : 1)} ${_getUnitDisplayText()})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final custom = _calculateCustomNutrition();
                            if (custom == null) {
                              // Show error message if calculation failed
                              if (_selectedUnit == ServingUnit.grams || _selectedUnit == ServingUnit.ounces) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Unable to calculate: Cannot determine the weight of the serving size "${widget.nutrition.servingSize ?? 'unknown'}". Please regenerate the nutrition info with weight information in the serving size (e.g., "1 slice (200g)").',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                );
                              }
                              return const SizedBox();
                            }
                            
                            return Column(
                              children: [
                                _buildNutritionRow(
                                  'Calories',
                                  '${custom['calories']}',
                                  'kcal',
                                  icon: Icons.local_fire_department,
                                  color: Colors.orange,
                                ),
                                _buildNutritionRow(
                                  'Protein',
                                  (custom['protein'] as double).toStringAsFixed(1),
                                  'g',
                                  icon: Icons.fitness_center,
                                  color: Colors.blue,
                                ),
                                _buildNutritionRow(
                                  'Carbohydrates',
                                  (custom['carbs'] as double).toStringAsFixed(1),
                                  'g',
                                  icon: Icons.energy_savings_leaf,
                                  color: Colors.green,
                                ),
                                _buildNutritionRow(
                                  'Fats',
                                  (custom['fats'] as double).toStringAsFixed(1),
                                  'g',
                                  icon: Icons.opacity,
                                  color: Colors.yellow.shade700,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                    
                    // Disclaimer
                    const Divider(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Disclaimer: These nutrition estimates are AI-generated and may be inaccurate. For precise nutritional information, consult a professional nutritionist or use verified nutrition databases.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit, {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? Colors.grey, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String getVitaminUnit(String vitamin) {
    // Most vitamins are in mg or mcg, default to mg
    if (vitamin.toLowerCase().contains('b') || vitamin.toLowerCase().contains('c')) {
      return 'mg';
    }
    return 'mg'; // Default
  }

  String getMineralUnit(String mineral) {
    // Most minerals are in mg
    return 'mg';
  }
}
