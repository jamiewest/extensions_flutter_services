import 'package:flutter/material.dart';

/// Extension on [ThemeMode] to provide additional functionality
/// for theme mode persistence and display.
extension ThemeModeExtension on ThemeMode {
  /// Returns a user-friendly display name for the theme mode.
  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Returns a description of what this theme mode does.
  String get description {
    switch (this) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme';
    }
  }

  /// Returns the icon that represents this theme mode.
  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Converts the theme mode to a string for persistence.
  String toStorageString() {
    return name; // 'light', 'dark', or 'system'
  }

  /// Creates a [ThemeMode] from a stored string value.
  /// Returns [ThemeMode.system] if the value is invalid.
  static ThemeMode fromStorageString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Returns the effective brightness for this theme mode.
  ///
  /// - If theme mode is light, returns [Brightness.light]
  /// - If theme mode is dark, returns [Brightness.dark]
  /// - If theme mode is system, returns the provided [platformBrightness]
  Brightness getEffectiveBrightness(Brightness platformBrightness) {
    switch (this) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return platformBrightness;
    }
  }
}
