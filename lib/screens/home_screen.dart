import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../services/recipe_service_supabase.dart';
import '../services/pantry_service.dart';
import '../services/preferences_service.dart';
import 'recipe_detail_screen.dart';
import 'recipe_detail_screen_new.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'add_recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final RecipeService _recipeService = RecipeService();
  final RecipeServiceSupabase _recipeServiceSupabase = RecipeServiceSupabase();
  final PantryService _pantryService = PantryService();
  final PreferencesService _preferencesService = PreferencesService();
  List<Recipe> _recipes = [];
  List<RecipeModel> _recipesYouCanMake = [];
  bool _isLoading = true;
  bool _pantryEnabled = false;
  bool _isLoadingPantryRecipes = false;
  bool _isInitialized = false; // Track if widget is initialized

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecipes();
    _loadPantryStatus().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload pantry status when app resumes
      _loadPantryStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload pantry status when dependencies change (including route changes)
    // Only reload if widget is initialized to avoid unnecessary calls
    if (_isInitialized) {
      _loadPantryStatus();
    }
  }

  Future<void> _loadPantryStatus() async {
    final isEnabled = await _preferencesService.isPantryEnabled();
    setState(() {
      _pantryEnabled = isEnabled;
    });
    if (isEnabled) {
      await _loadRecipesYouCanMake();
    } else {
      setState(() {
        _recipesYouCanMake = [];
      });
    }
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    final recipes = await _recipeService.getAllRecipes();
    final favorites = await _recipeService.getFavoriteIds();
    final recipesWithFavorites = recipes.map((recipe) {
      return recipe.copyWith(isFavorite: favorites.contains(recipe.id));
    }).toList();
    setState(() {
      _recipes = recipesWithFavorites;
      _isLoading = false;
    });
  }

  Future<void> _loadRecipesYouCanMake() async {
    if (!_pantryEnabled) return;
    
    setState(() => _isLoadingPantryRecipes = true);
    try {
      final pantryItems = await _pantryService.getPantryItems();
      if (pantryItems.isEmpty) {
        setState(() {
          _recipesYouCanMake = [];
          _isLoadingPantryRecipes = false;
        });
        return;
      }

      final pantryIngredientNames = pantryItems
          .map((item) => item.ingredientName.toLowerCase().trim())
          .toList();

      // Get all public recipes
      final allRecipes = await _recipeServiceSupabase.getRecipes(
        isPublic: true,
        limit: 100,
      );

      // Filter recipes that can be made with pantry items
      final recipesYouCanMake = allRecipes.where((recipe) {
        // Check if all ingredients are in pantry (fuzzy match)
        for (final ingredient in recipe.ingredients) {
          final ingredientName = ingredient.name.toLowerCase().trim();
          bool found = false;
          
          // Try exact match first
          for (final pantryName in pantryIngredientNames) {
            if (pantryName == ingredientName ||
                pantryName.contains(ingredientName) ||
                ingredientName.contains(pantryName)) {
              found = true;
              break;
            }
          }
          
          if (!found) {
            return false; // Recipe needs this ingredient
          }
        }
        return true; // All ingredients found
      }).toList();

      setState(() {
        _recipesYouCanMake = recipesYouCanMake;
        _isLoadingPantryRecipes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPantryRecipes = false;
      });
      // Silently fail - this is an optional feature
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cookpad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ).then((_) => _loadRecipes());
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              ).then((_) => _loadRecipes());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No recipes yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
                          ).then((_) => _loadRecipes());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Recipe'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadRecipes();
                    if (_pantryEnabled) {
                      await _loadRecipesYouCanMake();
                    }
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Recipes You Can Make Section (only if pantry is enabled)
                      if (_pantryEnabled && _recipesYouCanMake.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.kitchen, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recipes You Can Make Right Now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _isLoadingPantryRecipes
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _recipesYouCanMake.length,
                                    itemBuilder: (context, index) {
                                      final recipe = _recipesYouCanMake[index];
                                      return Container(
                                        width: 200,
                                        margin: const EdgeInsets.only(right: 16),
                                        child: _RecipeModelCard(
                                          recipe: recipe,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RecipeDetailScreenNew(recipe: recipe),
                                              ),
                                            ).then((_) {
                                              _loadRecipes();
                                              if (_pantryEnabled) {
                                                _loadRecipesYouCanMake();
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_menu, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text(
                                  'All Recipes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // All Recipes Grid
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
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
                                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                                    ),
                                  ).then((_) {
                                    _loadRecipes();
                                    if (_pantryEnabled) {
                                      _loadRecipesYouCanMake();
                                    }
                                  });
                                },
                                onFavoriteToggle: () async {
                                  await _recipeService.toggleFavorite(recipe.id);
                                  _loadRecipes();
                                },
                              );
                            },
                            childCount: _recipes.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
          ).then((_) {
            _loadRecipes();
            if (_pantryEnabled) {
              _loadRecipesYouCanMake();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecipeModelCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;

  const _RecipeModelCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings} servings',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: recipe.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(recipe.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: recipe.imageUrl == null
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onFavoriteToggle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.cookingTime} min',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings} servings',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
