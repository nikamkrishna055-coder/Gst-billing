import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_preference_service.dart';
import '../theme/app_theme.dart';

/// ThemeProvider manages the application theme state and persistence
class ThemeProvider extends ChangeNotifier {
  late ThemeMode _themeMode;

  ThemeProvider() : _themeMode = ThemeMode.light {
    _initializeTheme();
  }

  /// Get the current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Get the current theme data based on mode
  ThemeData get themeData {
    return _themeMode == ThemeMode.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
  }

  /// Check if dark mode is enabled
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize theme from saved preference
  Future<void> _initializeTheme() async {
    _themeMode = await ThemePreferenceService.loadThemeMode();
    // Also update AppTheme's ValueNotifier for backward compatibility
    AppTheme.themeModeNotifier.value = _themeMode;
    notifyListeners();
  }

  /// Set theme mode and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await ThemePreferenceService.saveThemeMode(mode);

    // Also update AppTheme's ValueNotifier for backward compatibility
    AppTheme.themeModeNotifier.value = mode;

    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final ThemeMode newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set dark mode (shorthand)
  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
