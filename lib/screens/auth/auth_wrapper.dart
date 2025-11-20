import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_navigation.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
    
    // Listen to auth changes to trigger rebuilds
    Supabase.instance.client.auth.onAuthStateChange.listen((AuthState state) {
      print('🔔 Auth state changed: ${state.event}, Mounted: $mounted');
      if (mounted) {
        // Just trigger a rebuild - we'll check current state in build()
        setState(() {});
      }
    });
  }

  Future<void> _initialize() async {
    // Give Supabase auth a moment to initialize and restore session
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _lastUserId = Supabase.instance.client.auth.currentUser?.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initialization
    if (_isInitializing) {
      print('🔄 AuthWrapper: Initializing...');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ALWAYS check current auth state directly from Supabase on each build
    final currentSession = Supabase.instance.client.auth.currentSession;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;
    
    // Debug logging
    print('🔄 AuthWrapper build - Session: ${currentSession != null}, User: ${currentUser != null}, UserId: $currentUserId');
    
    // Detect user change (switching accounts)
    if (currentUserId != null && currentUserId != _lastUserId && _lastUserId != null) {
      print('🔄 User switched from $_lastUserId to $currentUserId');
      _lastUserId = currentUserId;
    } else if (currentUserId != null && _lastUserId == null) {
      // First sign in or app restart with existing session
      print('🔄 User signed in: $currentUserId');
      _lastUserId = currentUserId;
    } else if (currentUserId == null && _lastUserId != null) {
      // User signed out
      print('🔄 User signed out (was $_lastUserId)');
      _lastUserId = null;
    }
    
    // Navigate based on current auth state from Supabase
    if (currentSession != null && currentUser != null) {
      print('✅ AuthWrapper: Navigating to MainNavigation for user: $currentUserId');
      return MainNavigation(key: ValueKey(currentUserId));
    } else {
      print('🔑 AuthWrapper: Showing LoginScreen');
      return const LoginScreen();
    }
  }
}
