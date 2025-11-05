import 'package:flutter/material.dart' hide Step;
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
  
  const MainNavigation({super.key, this.initialIndex = 0, this.remixRecipe});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  RecipeModel? _remixRecipe;
  final _notificationService = NotificationService();
  int _unreadCount = 0;

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

  List<Widget> get _screens => [
    const FeedScreen(),
    const SearchScreenNew(),
    GenerateRecipeScreen(remixRecipe: _remixRecipe),
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
      bottomNavigationBar: NavigationBar(
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '',
          ),
          NavigationDestination(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text(_formatUnreadCount(_unreadCount)),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: _unreadCount > 0
                ? Badge(
                    label: Text(_formatUnreadCount(_unreadCount)),
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications),
            label: '',
          ),
          const NavigationDestination(
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
