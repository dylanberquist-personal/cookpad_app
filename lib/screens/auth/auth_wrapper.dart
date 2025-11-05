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
  @override
  void initState() {
    super.initState();
    // Listen to initial auth state
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Give it a moment for auth state to settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check current session directly for more reliable state
        final session = Supabase.instance.client.auth.currentSession;
        final user = Supabase.instance.client.auth.currentUser;
        
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting && session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (session != null && user != null) {
          return const MainNavigation();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
