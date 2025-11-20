import 'package:flutter/material.dart';
import '../services/personalized_feed_service.dart';
import '../services/chef_leaderboard_service.dart';
import '../services/recipe_service_supabase.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../widgets/creator_profile_card.dart';
import 'recipe_detail_screen_new.dart';
import 'favorites_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _personalizedFeedService = PersonalizedFeedService();
  final _chefLeaderboardService = ChefLeaderboardService();
  final _recipeService = RecipeServiceSupabase();
  List<RecipeModel> _recipes = [];
  List<RecipeModel> _mealRecipes = [];
  List<UserModel> _topChefs = [];
  bool _isLoading = true;
  bool _isLoadingLeaderboard = true;
  String _currentMealType = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadLeaderboard();
    _loadMealRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _personalizedFeedService.getPersonalizedFeed();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoadingLeaderboard = true);
    try {
      final chefs = await _chefLeaderboardService.getTopChefs(limit: 5);
      setState(() {
        _topChefs = chefs;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      setState(() => _isLoadingLeaderboard = false);
      print('Error loading leaderboard: $e');
    }
  }

  Future<void> _loadMealRecipes() async {
    try {
      final currentHour = DateTime.now().hour;
      MealType mealType;
      String mealName;
      
      if (currentHour >= 5 && currentHour < 11) {
        mealType = MealType.breakfast;
        mealName = 'Breakfast';
      } else if (currentHour >= 11 && currentHour < 16) {
        mealType = MealType.lunch;
        mealName = 'Lunch';
      } else if (currentHour >= 16 && currentHour < 21) {
        mealType = MealType.dinner;
        mealName = 'Dinner';
      } else {
        mealType = MealType.snack;
        mealName = 'Snacks';
      }

      final recipes = await _recipeService.getRecipes(
        isPublic: true,
        limit: 10,
      );

      final mealFiltered = recipes.where((r) => r.mealType == mealType).toList();
      
      setState(() {
        _mealRecipes = mealFiltered;
        _currentMealType = mealName;
      });
    } catch (e) {
      print('Error loading meal recipes: $e');
    }
  }

  String _getMealTypeName() {
    return _currentMealType.isEmpty ? 'Recipes' : '$_currentMealType Recipes';
  }

  IconData _getMealTypeIcon() {
    switch (_currentMealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.restaurant;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.fastfood;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'Assets/Logo_long.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
            tooltip: 'Favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _loadRecipes(),
                  _loadLeaderboard(),
                  _loadMealRecipes(),
                ]);
              },
              child: CustomScrollView(
                slivers: [
                  // Top Chefs Section
                  if (_topChefs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildTopChefsSection(),
                    ),
                  
                  // Meal Recipes Section
                  if (_mealRecipes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildMealRecipesSection(),
                    ),
                  
                  // Top Picks for You Section
                  SliverToBoxAdapter(
                    child: _buildTopPicksSection(),
                  ),
                  
                  // Empty State
                  if (_recipes.isEmpty && _mealRecipes.isEmpty && _topChefs.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('No recipes yet')),
                    )
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark && iconColor == null 
                  ? Colors.white 
                  : (iconColor ?? Theme.of(context).primaryColor),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopChefsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Top Chefs',
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
        ),
        if (_isLoadingLeaderboard)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _topChefs.asMap().entries.map((entry) {
                final index = entry.key;
                final chef = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _topChefs.length - 1 ? 12 : 0),
                  child: _buildChefCardWithRank(chef, index + 1),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChefCardWithRank(UserModel chef, int rank) {
    Widget rankBadge;

    if (rank == 1) {
      rankBadge = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.looks_one, color: Colors.white, size: 20),
      );
    } else if (rank == 2) {
      rankBadge = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.looks_two, color: Colors.white, size: 20),
      );
    } else if (rank == 3) {
      rankBadge = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.brown[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.looks_3, color: Colors.white, size: 20),
      );
    } else {
      rankBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$rank',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Stack(
      children: [
        CreatorProfileCard(creator: chef),
        Positioned(
          top: 8,
          right: 8,
          child: rankBadge,
        ),
      ],
    );
  }

  Widget _buildMealRecipesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: _getMealTypeName(),
          icon: _getMealTypeIcon(),
          iconColor: isDark ? Colors.white : Theme.of(context).primaryColor,
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _mealRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _mealRecipes[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: _RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreenNew(recipe: recipe),
                      ),
                    ).then((_) => _loadMealRecipes());
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTopPicksSection() {
    // Filter out recipes that are already in the meal section
    final mealRecipeIds = _mealRecipes.map((r) => r.id).toSet();
    final topPicksRecipes = _recipes.where((r) => !mealRecipeIds.contains(r.id)).toList();
    
    if (topPicksRecipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Top Picks for You',
          icon: Icons.favorite,
          iconColor: Colors.red,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: topPicksRecipes.length,
            itemBuilder: (context, index) {
              final recipe = topPicksRecipes[index];
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
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${recipe.totalTime} min', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${recipe.averageRating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        size: 14,
                        color: recipe.difficultyLevel.name == 'easy'
                            ? Colors.green
                            : recipe.difficultyLevel.name == 'medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.difficultyLevel.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: recipe.difficultyLevel.name == 'easy'
                              ? Colors.green
                              : recipe.difficultyLevel.name == 'medium'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
