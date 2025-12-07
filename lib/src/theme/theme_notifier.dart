import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/material.dart';
import 'platform_brightness_service.dart';
import 'theme_service.dart';

/// A [ChangeNotifier] that manages the app's theme mode.
///
/// This notifier holds the current [ThemeMode] and notifies listeners
/// when the theme changes. It also persists changes using [ThemeService].
///
/// ## Usage with ServiceProvider
///
/// ```dart
/// // In main.dart
/// ..services.addSingleton<ThemeService>((services) => ThemeService())
/// ..services.addSingleton<ThemeNotifier>((services) => ThemeNotifier(
///       services.getRequiredService<ThemeService>(),
///     ))
///
/// // In app.dart
/// final themeNotifier = services.getRequiredService<ThemeNotifier>();
///
/// MaterialApp.router(
///   themeMode: themeNotifier.themeMode,
///   // ...
/// )
/// ```
///
/// ## Usage in Widgets
///
/// ```dart
/// // Listen to changes
/// class ThemeSettings extends StatelessWidget {
///   final ThemeNotifier themeNotifier;
///
///   @override
///   Widget build(BuildContext context) {
///     return ListenableBuilder(
///       listenable: themeNotifier,
///       builder: (context, _) {
///         return DropdownButton<ThemeMode>(
///           value: themeNotifier.themeMode,
///           onChanged: (mode) => themeNotifier.setThemeMode(mode!),
///           items: ThemeMode.values.map((mode) {
///             return DropdownMenuItem(
///               value: mode,
///               child: Text(mode.displayName),
///             );
///           }).toList(),
///         );
///       },
///     );
///   }
/// }
/// ```
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(
    this._themeService,
    this._platformBrightnessService,
    this._loggerFactory,
  );

  final ThemeService _themeService;
  final PlatformBrightnessService _platformBrightnessService;
  final LoggerFactory _loggerFactory;
  late final Logger _logger;

  ThemeMode _themeMode = ThemeMode.system;
  Brightness _platformBrightness = Brightness.light;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Initializes the notifier by loading the saved theme preference
  /// and setting up platform brightness monitoring.
  ///
  /// This should be called once during app startup, before the app
  /// widget is built.
  Future<void> initialize() async {
    _logger = _loggerFactory.createLogger('ThemeNotifier');

    // Load saved theme preference
    _themeMode = await _themeService.getThemeMode();
    _logger.logInformation('Loaded theme mode: ${_themeMode.name}');

    // Initialize platform brightness service
    _platformBrightnessService.initialize(
      onBrightnessChanged: _onPlatformBrightnessChanged,
    );

    _platformBrightness = _platformBrightnessService.currentBrightness;
    _logger.logInformation('Platform brightness: ${_platformBrightness.name}');

    notifyListeners();
  }

  /// Called when the platform brightness changes.
  void _onPlatformBrightnessChanged(Brightness brightness) {
    if (_platformBrightness == brightness) return;

    _platformBrightness = brightness;
    _logger.logInformation(
      'Platform brightness changed to: ${brightness.name}',
    );

    // If we're in system mode, notify listeners to update the theme
    if (_themeMode == ThemeMode.system) {
      _logger.logInformation(
        'Theme mode is system, UI will update to match platform brightness',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _platformBrightnessService.dispose();
    super.dispose();
  }

  /// Sets the theme mode and persists the change.
  ///
  /// Notifies all listeners of the change, which will cause the app
  /// to rebuild with the new theme.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _logger.logInformation('Changing theme mode to: ${mode.name}');
    _themeMode = mode;
    notifyListeners();

    await _themeService.saveThemeMode(mode);
    _logger.logInformation('Theme mode saved');
  }

  /// Resets the theme mode to system default.
  Future<void> resetToSystemDefault() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Returns true if the current theme mode is [ThemeMode.light].
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Returns true if the current theme mode is [ThemeMode.dark].
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Returns true if the current theme mode is [ThemeMode.system].
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Returns the current platform brightness (system-wide setting).
  ///
  /// This reflects what the operating system thinks the brightness should be,
  /// regardless of the app's current theme mode.
  Brightness get platformBrightness => _platformBrightness;

  /// Returns true if the platform is currently in dark mode.
  bool get isPlatformDarkMode => _platformBrightness == Brightness.dark;

  /// Returns true if the platform is currently in light mode.
  bool get isPlatformLightMode => _platformBrightness == Brightness.light;

  /// Returns the effective brightness that will be displayed.
  ///
  /// - If theme mode is light, returns Brightness.light
  /// - If theme mode is dark, returns Brightness.dark
  /// - If theme mode is system, returns the platform brightness
  Brightness get effectiveBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return _platformBrightness;
    }
  }

  /// Returns true if the effective theme being displayed is dark.
  bool get isEffectiveDark => effectiveBrightness == Brightness.dark;

  /// Returns true if the effective theme being displayed is light.
  bool get isEffectiveLight => effectiveBrightness == Brightness.light;
}
