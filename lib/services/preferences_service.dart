import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _pantryEnabledKey = 'pantry_feature_enabled';

  /// Check if pantry feature is enabled
  Future<bool> isPantryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pantryEnabledKey) ?? false; // Default to false
  }

  /// Enable pantry feature
  Future<void> enablePantry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pantryEnabledKey, true);
  }

  /// Disable pantry feature
  Future<void> disablePantry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pantryEnabledKey, false);
  }

  /// Toggle pantry feature
  Future<bool> togglePantry() async {
    final isEnabled = await isPantryEnabled();
    if (isEnabled) {
      await disablePantry();
      return false;
    } else {
      await enablePantry();
      return true;
    }
  }
}

