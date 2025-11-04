import 'package:flutter/material.dart';
import '../models/collection_model.dart';
import '../models/recipe_model.dart';
import '../services/collection_service.dart';
import 'recipe_detail_screen_new.dart';
import 'edit_collection_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final CollectionModel collection;
  final bool isOwner;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.isOwner,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _collectionService = CollectionService();
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;
  CollectionModel? _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _collectionService.getCollectionRecipes(widget.collection.id);
      final updatedCollection = await _collectionService.getCollectionById(widget.collection.id);
      
      setState(() {
        _recipes = recipes;
        _collection = updatedCollection ?? widget.collection;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipes: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeRecipe(RecipeModel recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Recipe'),
        content: Text('Remove "${recipe.title}" from this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _collectionService.removeRecipeFromCollection(
          widget.collection.id,
          recipe.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe removed')),
          );
          _loadRecipes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing recipe: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_collection?.name ?? widget.collection.name),
        actions: widget.isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCollectionScreen(
                          collection: _collection ?? widget.collection,
                        ),
                      ),
                    );
                    _loadRecipes();
                  },
                  tooltip: 'Edit Collection',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecipes,
              child: CustomScrollView(
                slivers: [
                  // Header section with collection info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_collection?.description != null &&
                              _collection!.description!.isNotEmpty) ...[
                            Text(
                              _collection!.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_collection?.recipeCount ?? _recipes.length} recipe${(_collection?.recipeCount ?? _recipes.length) != 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                _collection?.isPublic == true ? Icons.public : Icons.lock,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _collection?.isPublic == true ? 'Public' : 'Private',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  // Recipes grid
                  _recipes.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recipes in this collection',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.isOwner
                                      ? 'Add recipes to get started'
                                      : 'This collection is empty',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final recipe = _recipes[index];
                                return _RecipeCard(
                                  recipe: recipe,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecipeDetailScreenNew(recipe: recipe),
                                      ),
                                    ).then((_) => _loadRecipes());
                                  },
                                  onRemove: widget.isOwner
                                      ? () {
                                          _removeRecipe(recipe);
                                        }
                                      : null,
                                );
                              },
                              childCount: _recipes.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: recipe.imageUrls?.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(recipe.imageUrls!.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: recipe.imageUrls?.isEmpty != false
                        ? const Center(
                            child: Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                          )
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.totalTime} min',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.star, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.averageRating.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Remove button
            if (onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: onRemove,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

