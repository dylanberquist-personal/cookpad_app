import 'package:flutter/material.dart';
import '../services/recipe_service_supabase.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen_new.dart';

class SearchScreenNew extends StatefulWidget {
  const SearchScreenNew({super.key});

  @override
  State<SearchScreenNew> createState() => _SearchScreenNewState();
}

class _SearchScreenNewState extends State<SearchScreenNew> {
  final _recipeService = RecipeServiceSupabase();
  final _searchController = TextEditingController();
  List<RecipeModel> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _recipeService.searchRecipes(query);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final recipe = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: recipe.imageUrls?.isNotEmpty == true
                            ? ClipOval(
                                child: Image.network(
                                  recipe.imageUrls!.first,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                              )
                            : const Icon(Icons.restaurant_menu),
                      ),
                      title: Text(recipe.title),
                      subtitle: Text(recipe.description),
                      trailing: Text('⭐ ${recipe.averageRating.toStringAsFixed(1)}'),
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
                ),
    );
  }
}
