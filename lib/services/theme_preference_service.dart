import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle theme preference persistence
class ThemePreferenceService {
  static const String _themeKey = 'app_theme_mode';

  /// Save theme mode to local storage
  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String modeString = mode == ThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_themeKey, modeString);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  /// Load theme mode from local storage
  static Future<ThemeMode> loadThemeMode() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? modeString = prefs.getString(_themeKey);

      if (modeString == null) {
        return ThemeMode.light;
      }

      return modeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      print('Error loading theme mode: $e');
      return ThemeMode.light;
    }
  }

  /// Clear theme preference (reset to default)
  static Future<void> clearThemeMode() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
    } catch (e) {
      print('Error clearing theme mode: $e');
    }
  }
}
