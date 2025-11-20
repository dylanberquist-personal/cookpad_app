import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String _pantryEnabledKey = 'pantry_feature_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';

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
}

