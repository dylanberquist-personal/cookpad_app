import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import 'my_recipes_screen.dart';
import 'pantry_screen.dart';
import 'my_profile_detail_screen.dart';
import 'favorites_screen.dart';
import 'collections_screen.dart';
import 'shopping_lists_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _currentUser;
  bool _hasShownDialogThisSession = false;
  bool _isScreenVisible = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't load user data here - wait until screen is visible
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't automatically mark as visible - only show dialog when actually navigating to this screen
  }

  Future<void> _loadUserData({bool checkDialog = false}) async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        
        // Only check and show dialog if explicitly requested (on first initialization)
        if (checkDialog && _isScreenVisible && !_hasShownDialogThisSession) {
          // Small delay to ensure UI is ready
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && _isScreenVisible) {
            await _checkAndShowProfileDialog();
          }
        }
      }
    } catch (e) {
      // Silently handle error
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkAndShowProfileDialog() async {
    print('Checking profile dialog...');
    
    // Only show if user has incomplete profile
    if (_currentUser == null) {
      print('No current user, skipping dialog');
      return;
    }
    
    // Check if user has default PFP (no profile picture) or no bio/about
    final hasDefaultPFP = _currentUser!.profilePictureUrl == null || 
                          _currentUser!.profilePictureUrl!.isEmpty;
    final hasNoBio = _currentUser!.bio == null || _currentUser!.bio!.isEmpty;
    
    print('Profile check - Default PFP: $hasDefaultPFP, No Bio: $hasNoBio');
    
    // Only show if user has default PFP OR no bio
    if (!hasDefaultPFP && !hasNoBio) {
      print('Profile is complete, skipping dialog');
      return;
    }

    // Only check session flag - show once per session
    if (_hasShownDialogThisSession) {
      print('Dialog already shown this session, skipping');
      return;
    }

    print('Showing profile dialog');
    
    if (mounted && _isScreenVisible) {
      _hasShownDialogThisSession = true;
      _showProfileDialog();
    }
  }

  Future<void> _showProfileDialog() async {
    if (!mounted) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompleteProfileDialog(
        onComplete: () {
          if (mounted) {
            Navigator.pop(context);
            // Navigate to profile detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyProfileDetailScreen(userId: userId),
              ),
            ).then((_) {
              // Reload user data after returning
              if (mounted) {
                _loadUserData();
              }
            });
          }
        },
        onDismiss: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    
    // Mark screen as visible when build is called (means it's actually being displayed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isScreenVisible) {
        setState(() {
          _isScreenVisible = true;
        });
        // Only initialize once - don't reset dialog flag when navigating back
        if (!_hasInitialized) {
          _hasInitialized = true;
          // Load user data and check for dialog on first initialization
          _loadUserData(checkDialog: true);
        } else {
          // Just reload user data when navigating back, but don't check for dialog
          _loadUserData(checkDialog: false);
        }
      }
    });
    
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
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyProfileDetailScreen(userId: userId),
                      ),
                    );
                    // Reload user data after returning from profile edit
                    if (mounted) {
                      _loadUserData();
                    }
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
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    // Theme changes will be applied when app resumes
                    // The MyApp widget listens to lifecycle changes
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

class _CompleteProfileDialog extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const _CompleteProfileDialog({
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              'Add a profile picture and bio to help others get to know you better!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Complete Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
