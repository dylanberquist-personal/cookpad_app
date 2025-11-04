import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'auth/login_screen.dart';
import 'my_recipes_screen.dart';
import 'pantry_screen.dart';
import 'my_profile_detail_screen.dart';
import 'favorites_screen.dart';
import 'collections_screen.dart';
import 'shopping_lists_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              children: [
                ListTile(
                  title: const Text('My Profile'),
                  leading: const Icon(Icons.person),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyProfileDetailScreen(userId: userId),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('My Recipes'),
                  leading: const Icon(Icons.restaurant_menu),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyRecipesScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Favorites'),
                  leading: const Icon(Icons.favorite),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Collections'),
                  leading: const Icon(Icons.folder),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CollectionsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Shopping Lists'),
                  leading: const Icon(Icons.shopping_cart),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShoppingListsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Pantry'),
                  leading: const Icon(Icons.kitchen),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PantryScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Settings'),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
                ListTile(
                  title: const Text('Sign Out'),
                  leading: const Icon(Icons.logout),
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}
