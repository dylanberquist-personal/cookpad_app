import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class RecipeService {
  static const String _recipesKey = 'recipes';
  static const String _favoritesKey = 'favorites';

  // Sample recipes for initial data
  static List<Recipe> _initialRecipes = [
    Recipe(
      id: '1',
      title: 'Classic Spaghetti Carbonara',
      description: 'A traditional Italian pasta dish with eggs, cheese, and crispy pancetta.',
      imageUrl: null,
      ingredients: [
        Ingredient(name: 'Spaghetti', quantity: '400', unit: 'g'),
        Ingredient(name: 'Eggs', quantity: '4', unit: ''),
        Ingredient(name: 'Pancetta', quantity: '150', unit: 'g'),
        Ingredient(name: 'Parmesan cheese', quantity: '100', unit: 'g'),
        Ingredient(name: 'Black pepper', quantity: 'To taste', unit: ''),
      ],
      steps: [
        Step(stepNumber: 1, instruction: 'Cook spaghetti according to package instructions until al dente.'),
        Step(stepNumber: 2, instruction: 'While pasta cooks, fry pancetta until crispy.'),
        Step(stepNumber: 3, instruction: 'Beat eggs and mix with grated parmesan cheese.'),
        Step(stepNumber: 4, instruction: 'Drain pasta, reserving some pasta water.'),
        Step(stepNumber: 5, instruction: 'Quickly mix hot pasta with egg mixture, adding pancetta and pasta water.'),
        Step(stepNumber: 6, instruction: 'Season with black pepper and serve immediately.'),
      ],
      cookingTime: 20,
      servings: 4,
      author: 'Chef Mario',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 45,
    ),
    Recipe(
      id: '2',
      title: 'Chicken Tikka Masala',
      description: 'Creamy and flavorful Indian curry with tender chicken pieces.',
      imageUrl: null,
      ingredients: [
        Ingredient(name: 'Chicken breast', quantity: '500', unit: 'g'),
        Ingredient(name: 'Tomato sauce', quantity: '400', unit: 'ml'),
        Ingredient(name: 'Heavy cream', quantity: '200', unit: 'ml'),
        Ingredient(name: 'Onions', quantity: '2', unit: ''),
        Ingredient(name: 'Garlic', quantity: '4', unit: 'cloves'),
        Ingredient(name: 'Garam masala', quantity: '2', unit: 'tsp'),
        Ingredient(name: 'Turmeric', quantity: '1', unit: 'tsp'),
      ],
      steps: [
        Step(stepNumber: 1, instruction: 'Cut chicken into bite-sized pieces and marinate with spices for 30 minutes.'),
        Step(stepNumber: 2, instruction: 'Heat oil in a pan and cook chicken until golden.'),
        Step(stepNumber: 3, instruction: 'Add chopped onions and garlic, cook until soft.'),
        Step(stepNumber: 4, instruction: 'Add tomato sauce and spices, simmer for 10 minutes.'),
        Step(stepNumber: 5, instruction: 'Stir in heavy cream and cook for 5 more minutes.'),
        Step(stepNumber: 6, instruction: 'Serve hot with rice or naan bread.'),
      ],
      cookingTime: 45,
      servings: 4,
      author: 'Chef Priya',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      likes: 78,
    ),
    Recipe(
      id: '3',
      title: 'Chocolate Chip Cookies',
      description: 'Soft and chewy cookies with melty chocolate chips - the perfect treat!',
      imageUrl: null,
      ingredients: [
        Ingredient(name: 'All-purpose flour', quantity: '250', unit: 'g'),
        Ingredient(name: 'Butter', quantity: '115', unit: 'g'),
        Ingredient(name: 'Brown sugar', quantity: '100', unit: 'g'),
        Ingredient(name: 'White sugar', quantity: '50', unit: 'g'),
        Ingredient(name: 'Egg', quantity: '1', unit: ''),
        Ingredient(name: 'Chocolate chips', quantity: '200', unit: 'g'),
        Ingredient(name: 'Vanilla extract', quantity: '1', unit: 'tsp'),
        Ingredient(name: 'Baking soda', quantity: '1', unit: 'tsp'),
      ],
      steps: [
        Step(stepNumber: 1, instruction: 'Preheat oven to 180°C (350°F).'),
        Step(stepNumber: 2, instruction: 'Cream butter and sugars until light and fluffy.'),
        Step(stepNumber: 3, instruction: 'Beat in egg and vanilla extract.'),
        Step(stepNumber: 4, instruction: 'Mix in flour and baking soda until just combined.'),
        Step(stepNumber: 5, instruction: 'Fold in chocolate chips.'),
        Step(stepNumber: 6, instruction: 'Drop rounded tablespoons onto baking sheet and bake for 10-12 minutes.'),
      ],
      cookingTime: 30,
      servings: 24,
      author: 'Chef Sarah',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 92,
    ),
  ];

  Future<List<Recipe>> getAllRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getString(_recipesKey);
    
    if (recipesJson != null) {
      final List<dynamic> decoded = json.decode(recipesJson);
      return decoded.map((r) => Recipe.fromJson(r)).toList();
    } else {
      // Initialize with sample recipes
      await saveRecipes(_initialRecipes);
      return _initialRecipes;
    }
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = json.encode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_recipesKey, recipesJson);
  }

  Future<void> addRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    recipes.add(recipe);
    await saveRecipes(recipes);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      recipes[index] = recipe;
      await saveRecipes(recipes);
    }
  }

  Future<void> deleteRecipe(String id) async {
    final recipes = await getAllRecipes();
    recipes.removeWhere((r) => r.id == id);
    await saveRecipes(recipes);
    
    // Also remove from favorites
    final favorites = await getFavoriteIds();
    favorites.remove(id);
    await saveFavoriteIds(favorites);
  }

  Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson != null) {
      final List<dynamic> decoded = json.decode(favoritesJson);
      return decoded.cast<String>();
    }
    return [];
  }

  Future<void> saveFavoriteIds(List<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = json.encode(favoriteIds);
    await prefs.setString(_favoritesKey, favoritesJson);
  }

  Future<void> toggleFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    if (favorites.contains(recipeId)) {
      favorites.remove(recipeId);
    } else {
      favorites.add(recipeId);
    }
    await saveFavoriteIds(favorites);
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final recipes = await getAllRecipes();
    final favorites = await getFavoriteIds();
    return recipes.where((r) => favorites.contains(r.id)).toList();
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final recipes = await getAllRecipes();
    final lowerQuery = query.toLowerCase();
    return recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(lowerQuery) ||
          recipe.description.toLowerCase().contains(lowerQuery) ||
          recipe.ingredients.any((ing) => ing.name.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
