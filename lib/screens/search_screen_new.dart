import 'package:flutter/material.dart';
import '../services/recipe_service_supabase.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../widgets/creator_profile_card.dart';
import 'recipe_detail_screen_new.dart';

class SearchScreenNew extends StatefulWidget {
  const SearchScreenNew({super.key});

  @override
  State<SearchScreenNew> createState() => _SearchScreenNewState();
}

class _SearchScreenNewState extends State<SearchScreenNew> {
  final _recipeService = RecipeServiceSupabase();
  final _searchController = TextEditingController();
  List<RecipeModel> _recipeResults = [];
  List<UserModel> _userResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _recipeResults = [];
        _userResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final recipes = await _recipeService.searchRecipes(query);
      final users = await _recipeService.searchUsers(query);
      setState(() {
        _recipeResults = recipes;
        _userResults = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _recipeResults.isNotEmpty || _userResults.isNotEmpty;
    final isEmpty = _searchController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search recipes...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _search('');
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Search for recipes and users',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : !hasResults
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Users Section
                        if (_userResults.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Users',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final user = _userResults[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: CreatorProfileCard(creator: user),
                                );
                              },
                              childCount: _userResults.length,
                            ),
                          ),
                        ],
                        // Recipes Section
                        if (_recipeResults.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.restaurant_menu, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recipes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                  final recipe = _recipeResults[index];
                                  return _RecipeCard(
                                    recipe: recipe,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RecipeDetailScreenNew(recipe: recipe),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _recipeResults.length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                        recipe.difficultyLevel.name == 'medium' ? 'INTERMEDIATE' : recipe.difficultyLevel.name.toUpperCase(),
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
