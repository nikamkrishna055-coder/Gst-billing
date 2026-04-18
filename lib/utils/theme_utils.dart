import 'package:flutter/material.dart';

/// Helper utilities for theme-aware color selection
class ThemeUtils {
  ThemeUtils._();

  /// Get success color based on current theme
  static Color successColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Get error color based on current theme
  static Color errorColor(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Get warning color based on current theme
  static Color warningColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  /// Get info color based on current theme
  static Color infoColor(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  /// Get primary text color
  static Color primaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Get secondary text color
  static Color secondaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

  /// Get surface/card color
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Get background color
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Get divider color
  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  /// Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
