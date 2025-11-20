import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/preferences_service.dart';

// Global notifier for theme changes
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // 🔍 DEBUG: Print what was loaded from .env
  print('🔍 DEBUG: .env file loaded');
  print('   All env vars: ${dotenv.env.keys.toList()}');
  print('   SUPABASE_URL exists: ${dotenv.env.containsKey('SUPABASE_URL')}');
  print('   OPENAI_API_KEY exists: ${dotenv.env.containsKey('OPENAI_API_KEY')}');
  print('   RAPIDAPI_KEY exists: ${dotenv.env.containsKey('RAPIDAPI_KEY')}');
  
  if (dotenv.env.containsKey('RAPIDAPI_KEY')) {
    final key = dotenv.env['RAPIDAPI_KEY']!;
    print('   RAPIDAPI_KEY length: ${key.length} characters');
    if (key.length >= 10) {
      print('   RAPIDAPI_KEY preview: ${key.substring(0, 10)}...${key.substring(key.length - 4)}');
    }
  } else {
    print('   ⚠️ RAPIDAPI_KEY NOT FOUND IN .env FILE!');
  }
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://sfyidxcygzeeltkuwwyo.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmeWlkeGN5Z3plZWx0a3V3d3lvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMjc3NzcsImV4cCI6MjA3NzcwMzc3N30.BjJTwEQqC6KopkVUsCOWuyczO8dHKcvIzqVbH7zlWIE',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _preferencesService = PreferencesService();
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoadingTheme = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
    // Listen to theme changes from settings screen
    themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    _loadThemeMode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload theme when app resumes
      _loadThemeMode();
    }
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await _preferencesService.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
        _isLoadingTheme = false;
      });
      // Update the global notifier
      themeModeNotifier.value = themeMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while theme is loading (only on first load)
    if (_isLoadingTheme) {
      return MaterialApp(
        title: 'Cookpad',
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }
    
    return MaterialApp(
      title: 'Cookpad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
