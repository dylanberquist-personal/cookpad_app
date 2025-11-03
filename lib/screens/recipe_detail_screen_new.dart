import 'package:flutter/material.dart' hide Step;
import '../models/recipe_model.dart';
import '../services/recipe_service_supabase.dart';
import '../config/supabase_config.dart';

class RecipeDetailScreenNew extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreenNew({super.key, required this.recipe});

  @override
  State<RecipeDetailScreenNew> createState() => _RecipeDetailScreenNewState();
}

class _RecipeDetailScreenNewState extends State<RecipeDetailScreenNew> {
  late RecipeModel _recipe;
  final _recipeService = RecipeServiceSupabase();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final recipe = await _recipeService.getRecipeById(widget.recipe.id, currentUserId: userId);
    setState(() {
      _recipe = recipe ?? widget.recipe;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    await _recipeService.toggleFavorite(_recipe.id);
    await _loadRecipe();
  }

  Future<void> _rateRecipe(int rating) async {
    await _recipeService.rateRecipe(_recipe.id, rating);
    await _loadRecipe();
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
                  ? Image.network(_recipe.imageUrls!.first, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(_recipe.isFavorite == true ? Icons.favorite : Icons.favorite_border),
                color: _recipe.isFavorite == true ? Colors.red : Colors.white,
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
                  if (_recipe.userRating != null) ...[
                    Text('Your Rating: ${_recipe.userRating} ⭐'),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < (_recipe.userRating ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => _rateRecipe(index + 1),
                      );
                    }),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
