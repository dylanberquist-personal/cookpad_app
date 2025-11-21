import 'package:flutter/material.dart' hide Step;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'feed_screen.dart';
import 'search_screen_new.dart';
import 'generate_recipe_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../models/recipe_model.dart';
import '../services/notification_service.dart';
import '../config/supabase_config.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final RecipeModel? remixRecipe;
  final bool isFromLogin;
  
  const MainNavigation({super.key, this.initialIndex = 0, this.remixRecipe, this.isFromLogin = false});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  RecipeModel? _remixRecipe;
  final _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isFabMenuOpen = false;
  File? _initialImage;
  String? _initialMessage;
  Key _generateRecipeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Store remixRecipe only on initial load
    _remixRecipe = widget.remixRecipe;
    _loadUnreadCount();
    // Refresh unread count periodically
    _startPeriodicRefresh();
    
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _unreadCount = 0;
      });
      return;
    }

    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  String _formatUnreadCount(int count) {
    if (count == 0) return '';
    if (count < 10) return count.toString();
    return '10+';
  }

  void _openRecipeGenerator() {
    setState(() {
      _isFabMenuOpen = false;
      _initialImage = null;
      _initialMessage = null;
      _generateRecipeKey = UniqueKey(); // Force recreation
      _currentIndex = 2;
    });
  }

  Future<void> _openImagePicker() async {
    setState(() => _isFabMenuOpen = false);
    
    final ImagePicker picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _initialImage = File(image.path);
          _initialMessage = null;
          _generateRecipeKey = UniqueKey(); // Force recreation
          _currentIndex = 2;
        });
      }
    }
  }

  Future<void> _openLinkInput() async {
    setState(() => _isFabMenuOpen = false);
    
    final TextEditingController linkController = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Recipe Link'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'Paste URL here...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (linkController.text.trim().isNotEmpty) {
                Navigator.pop(context, linkController.text);
              }
            },
            child: const Text('Extract Recipe'),
          ),
        ],
      ),
    );

    if (link != null && link.trim().isNotEmpty) {
      setState(() {
        _initialImage = null;
        _initialMessage = link.trim();
        _generateRecipeKey = UniqueKey(); // Force recreation
        _currentIndex = 2;
      });
    }
  }

  void _toggleFabMenu() {
    setState(() => _isFabMenuOpen = !_isFabMenuOpen);
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _screens => [
    const FeedScreen(),
    const SearchScreenNew(),
    GenerateRecipeScreen(
      key: _generateRecipeKey,
      remixRecipe: _remixRecipe,
      initialImage: _initialImage,
      initialMessage: _initialMessage,
    ),
    NotificationsScreen(onUnreadCountChanged: _loadUnreadCount),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            // Dismiss keyboard before navigation
            FocusScope.of(context).unfocus();
            setState(() => _currentIndex = index);
            // Refresh unread count when navigating to notifications
            if (index == 3) {
              _loadUnreadCount();
            }
          },
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 20),
              selectedIcon: Icon(Icons.home, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, size: 20),
              selectedIcon: Icon(Icons.search, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, size: 20),
              selectedIcon: Icon(Icons.auto_awesome, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: _unreadCount > 0
                  ? Badge(
                      label: Text(_formatUnreadCount(_unreadCount), style: TextStyle(fontSize: 10)),
                      child: Icon(Icons.notifications_outlined, size: 20),
                    )
                  : Icon(Icons.notifications_outlined, size: 20),
              selectedIcon: _unreadCount > 0
                  ? Badge(
                      label: Text(_formatUnreadCount(_unreadCount), style: TextStyle(fontSize: 10)),
                      child: Icon(Icons.notifications, size: 20),
                    )
                  : Icon(Icons.notifications, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 20),
              selectedIcon: Icon(Icons.person, size: 20),
              label: '',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3 || _currentIndex == 4
          ? null
          : Stack(
              children: [
                // Backdrop to close menu
                if (_isFabMenuOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFabMenuOpen = false),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                // Menu items
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isFabMenuOpen) ...[
                      _buildFabMenuItem(
                        icon: Icons.auto_awesome,
                        label: 'Recipe Generator',
                        onTap: _openRecipeGenerator,
                      ),
                      const SizedBox(height: 12),
                      _buildFabMenuItem(
                        icon: Icons.image,
                        label: 'Image',
                        onTap: _openImagePicker,
                      ),
                      const SizedBox(height: 12),
                      _buildFabMenuItem(
                        icon: Icons.link,
                        label: 'Link',
                        onTap: _openLinkInput,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Main FAB
                    FloatingActionButton(
                      onPressed: _toggleFabMenu,
                      child: AnimatedRotation(
                        turns: _isFabMenuOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(_isFabMenuOpen ? Icons.close : Icons.add),
                      ),
                      tooltip: 'Generate Recipe',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
