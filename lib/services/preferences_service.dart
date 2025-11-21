import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String _pantryEnabledKey = 'pantry_feature_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _dietaryHintSeenKey = 'dietary_hint_seen';
  static const String _pantryHintSeenKey = 'pantry_hint_seen';
  static const String _profileHintSeenKey = 'profile_hint_seen';
  static const String _generateRecipeHintSeenKey = 'generate_recipe_hint_seen';
  static const String _isFromLoginKey = 'is_from_login';

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

  /// Get theme mode (light, dark, or system)
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == null) {
      return ThemeMode.system; // Default to system
    }
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, modeString);
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to enabled
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, true);
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);
  }

  /// Toggle notifications
  Future<bool> toggleNotifications() async {
    final isEnabled = await areNotificationsEnabled();
    if (isEnabled) {
      await disableNotifications();
      return false;
    } else {
      await enableNotifications();
      return true;
    }
  }

  /// Check if dietary hint has been seen
  Future<bool> hasSeenDietaryHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dietaryHintSeenKey) ?? false; // Default to false
  }

  /// Mark dietary hint as seen
  Future<void> setDietaryHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dietaryHintSeenKey, true);
  }

  /// Reset dietary hint (for testing or after profile update)
  Future<void> resetDietaryHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dietaryHintSeenKey, false);
  }

  /// Check if pantry hint has been seen
  Future<bool> hasSeenPantryHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pantryHintSeenKey) ?? false;
  }

  /// Mark pantry hint as seen
  Future<void> setPantryHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pantryHintSeenKey, true);
  }

  /// Reset pantry hint (for testing)
  Future<void> resetPantryHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pantryHintSeenKey, false);
  }

  /// Check if profile hint has been seen
  Future<bool> hasSeenProfileHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileHintSeenKey) ?? false;
  }

  /// Mark profile hint as seen
  Future<void> setProfileHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileHintSeenKey, true);
  }

  /// Reset profile hint (for testing)
  Future<void> resetProfileHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileHintSeenKey, false);
  }

  /// Check if generate recipe hint has been seen
  Future<bool> hasSeenGenerateRecipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_generateRecipeHintSeenKey) ?? false;
  }

  /// Mark generate recipe hint as seen
  Future<void> setGenerateRecipeHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_generateRecipeHintSeenKey, true);
  }

  /// Reset generate recipe hint (for testing)
  Future<void> resetGenerateRecipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_generateRecipeHintSeenKey, false);
  }

  /// Check if user is coming from login
  Future<bool> isFromLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFromLoginKey) ?? false;
  }

  /// Mark that user is coming from login
  Future<void> setFromLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFromLoginKey, value);
  }
}

