import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/user_model.dart';
import '../services/recipe_service.dart';
import '../config/supabase_config.dart';
import '../widgets/creator_profile_card.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final _supabase = SupabaseConfig.client;
  late Recipe _recipe;
  bool _isLoading = true;
  UserModel? _creator;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
    _loadCreator();
  }

  Future<void> _loadRecipe() async {
    final favorites = await _recipeService.getFavoriteIds();
    setState(() {
      _recipe = widget.recipe.copyWith(
        isFavorite: favorites.contains(widget.recipe.id),
      );
      _isLoading = false;
    });
  }

  Future<void> _loadCreator() async {
    // Try to load user by username from author field
    // Remove "Chef " prefix if present
    String authorName = widget.recipe.author;
    if (authorName.startsWith('Chef ')) {
      authorName = authorName.substring(6);
    }
    
    setState(() {
      _isLoadingCreator = true;
    });

    try {
      // Try to find user by username (case-insensitive)
      final response = await _supabase
          .from('users')
          .select()
          .ilike('username', authorName)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _creator = UserModel.fromJson(response);
          _isLoadingCreator = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCreator = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCreator = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    await _recipeService.toggleFavorite(_recipe.id);
    setState(() {
      _recipe = _recipe.copyWith(isFavorite: !_recipe.isFavorite);
    });
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
              background: _recipe.imageUrl != null
                  ? Image.network(_recipe.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _recipe.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
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
                  Text(
                    _recipe.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.access_time,
                        label: '${_recipe.cookingTime} min',
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.people,
                        label: '${_recipe.servings} servings',
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.favorite,
                        label: '${_recipe.likes}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._recipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${ingredient.quantity}${ingredient.unit != null ? ' ${ingredient.unit}' : ''} ${ingredient.name}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.value.stepNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.value.instruction,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Creator Profile Card
                  if (_isLoadingCreator)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_creator != null)
                    CreatorProfileCard(
                      creator: _creator,
                      userId: _creator!.id,
                    )
                  else
                    // Fallback: show author name in a card format
                    InkWell(
                      onTap: null, // Not navigable without user info
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                _recipe.author.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Created by',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _recipe.author,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
