import 'package:flutter/material.dart' hide Step;
import 'feed_screen.dart';
import 'search_screen_new.dart';
import 'generate_recipe_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../models/recipe_model.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final RecipeModel? remixRecipe;
  
  const MainNavigation({super.key, this.initialIndex = 0, this.remixRecipe});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  RecipeModel? _remixRecipe;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Store remixRecipe only on initial load
    _remixRecipe = widget.remixRecipe;
  }

  List<Widget> get _screens => [
    const FeedScreen(),
    const SearchScreenNew(),
    GenerateRecipeScreen(remixRecipe: _remixRecipe),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // Dismiss keyboard before navigation
          FocusScope.of(context).unfocus();
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3 || _currentIndex == 4
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              child: const Icon(Icons.add),
              tooltip: 'Generate Recipe',
            ),
    );
  }
}
