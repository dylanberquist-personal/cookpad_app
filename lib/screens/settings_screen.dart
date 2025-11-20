import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/notification_badge_icon.dart';
import 'auth/login_screen.dart';
import 'main_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _preferencesService = PreferencesService();
  final _authService = AuthService();
  
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }


  Future<void> _loadSettings() async {
    final notificationsEnabled = await _preferencesService.areNotificationsEnabled();
    final themeMode = await _preferencesService.getThemeMode();
    
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _themeMode = themeMode;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications() async {
    final newValue = await _preferencesService.toggleNotifications();
    setState(() {
      _notificationsEnabled = newValue;
    });
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    await _preferencesService.setThemeMode(mode);
    setState(() {
      _themeMode = mode;
    });
    // Notify the app to reload theme immediately
    themeModeNotifier.value = mode;
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, recipes, and content will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show second confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance to cancel. Your account and all data will be permanently deleted. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteAccount();
      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive notifications for follows, likes, comments, and more'),
            value: _notificationsEnabled,
            onChanged: (value) => _toggleNotifications(),
            secondary: const Icon(Icons.notifications),
          ),
          
          const Divider(),
          
          // Theme Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (value) {
              if (value != null) _changeThemeMode(value);
            },
            secondary: const Icon(Icons.light_mode),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (value) {
              if (value != null) _changeThemeMode(value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follow device theme'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (value) {
              if (value != null) _changeThemeMode(value);
            },
            secondary: const Icon(Icons.brightness_auto),
          ),
          
          const Divider(),
          
          // Account Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account and all data'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            trailing: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isDeleting ? null : _deleteAccount,
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
          selectedIndex: 4,
          onDestinationSelected: (index) {
            if (index == 4) {
              // Go back to profile screen
              Navigator.of(context).pop();
              return;
            }
            // Navigate to main navigation with the selected index
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainNavigation(initialIndex: index),
              ),
              (route) => false,
            );
          },
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
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
              icon: NotificationBadgeIcon(isSelected: false),
              selectedIcon: NotificationBadgeIcon(isSelected: true),
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
    );
  }
}

