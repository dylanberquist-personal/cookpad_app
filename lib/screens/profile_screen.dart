import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'auth/login_screen.dart';

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
                  title: const Text('My Recipes'),
                  leading: const Icon(Icons.restaurant_menu),
                  onTap: () {
                    // TODO: Navigate to user's recipes
                  },
                ),
                ListTile(
                  title: const Text('Favorites'),
                  leading: const Icon(Icons.favorite),
                  onTap: () {
                    // TODO: Navigate to favorites
                  },
                ),
                ListTile(
                  title: const Text('Collections'),
                  leading: const Icon(Icons.folder),
                  onTap: () {
                    // TODO: Navigate to collections
                  },
                ),
                ListTile(
                  title: const Text('Shopping Lists'),
                  leading: const Icon(Icons.shopping_cart),
                  onTap: () {
                    // TODO: Navigate to shopping lists
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
