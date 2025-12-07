import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode_extensions.dart';

/// Service responsible for persisting and loading theme preferences.
///
/// This service uses [SharedPreferences] to store the user's theme mode
/// preference. The preference is stored as a string ('light', 'dark', or 'system').
///
/// ## Usage
///
/// ```dart
/// final themeService = ThemeService();
/// await themeService.initialize();
///
/// // Get saved theme mode
/// final savedMode = await themeService.getThemeMode();
///
/// // Save theme mode
/// await themeService.saveThemeMode(ThemeMode.dark);
/// ```
class ThemeService {
  static const String _themeModeKey = 'theme_mode';

  SharedPreferences? _prefs;

  /// Initializes the service by loading SharedPreferences.
  /// This must be called before using other methods.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Returns the saved theme mode, or [ThemeMode.system] if none is saved.
  ///
  /// Defaults to [ThemeMode.system] to follow the device's theme preference.
  Future<ThemeMode> getThemeMode() async {
    if (_prefs == null) {
      await initialize();
    }

    final savedValue = _prefs!.getString(_themeModeKey);
    return ThemeModeExtension.fromStorageString(savedValue);
  }

  /// Saves the theme mode preference.
  ///
  /// Returns true if the save was successful, false otherwise.
  Future<bool> saveThemeMode(ThemeMode mode) async {
    if (_prefs == null) {
      await initialize();
    }

    return await _prefs!.setString(_themeModeKey, mode.toStorageString());
  }

  /// Clears the saved theme mode preference.
  ///
  /// After clearing, [getThemeMode] will return [ThemeMode.system].
  Future<bool> clearThemeMode() async {
    if (_prefs == null) {
      await initialize();
    }

    return await _prefs!.remove(_themeModeKey);
  }
}
