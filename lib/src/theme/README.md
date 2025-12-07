# Theme System

This folder contains a complete theme management system with user selection and persistence.

## Overview

The theme system provides:
- **Light and Dark themes** based on Material Design 3
- **System theme support** that follows device settings
- **User preference persistence** using SharedPreferences
- **ChangeNotifier pattern** for reactive theme updates
- **Multiple UI widgets** for theme selection

## Architecture

```
┌─────────────────────────────────────────────────┐
│ User selects theme (ThemeSettingsWidget)        │
└───────────────┬─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────┐
│ ThemeNotifier (ChangeNotifier)                  │
│ - Holds current ThemeMode                       │
│ - Notifies listeners on change                  │
└───────────────┬─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────┐
│ ThemeService (Persistence Layer)                │
│ - Saves to SharedPreferences                    │
│ - Loads saved preference                        │
└───────────────┬─────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────┐
│ MaterialApp applies theme                       │
│ - themeMode: ThemeMode.light/dark/system        │
│ - theme: AppTheme.lightTheme                    │
│ - darkTheme: AppTheme.darkTheme                 │
└─────────────────────────────────────────────────┘
```

## Components

### app_theme.dart

Defines the light and dark themes for the app using Material Design 3.

**Key features:**
- Color schemes generated from seed colors
- Customizable component themes
- Utility methods for theme detection

**Customization:**
```dart
// Change the primary color
static const Color _primarySeedColor = Colors.purple; // Instead of blue

// Customize themes
static ThemeData get lightTheme {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primarySeedColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // Add custom theme properties here
  );
}
```

### theme_service.dart

Handles persistence of theme preferences using SharedPreferences.

**Key methods:**
- `initialize()` - Load SharedPreferences
- `getThemeMode()` - Get saved theme mode (defaults to system)
- `saveThemeMode(ThemeMode)` - Save user's theme preference
- `clearThemeMode()` - Reset to default

### theme_notifier.dart

A `ChangeNotifier` that manages the current theme mode and notifies listeners of changes.

**Key features:**
- Reactive theme updates using `notifyListeners()`
- Automatic persistence via `ThemeService`
- Helper properties: `isLightMode`, `isDarkMode`, `isSystemMode`

### theme_mode_extension.dart

Extension methods on `ThemeMode` for enhanced functionality.

**Provides:**
- `displayName` - User-friendly names ("Light", "Dark", "System")
- `description` - Descriptions of each mode
- `icon` - Icons for each mode
- `toStorageString()` / `fromStorageString()` - Persistence helpers

### theme_settings_widget.dart

Collection of pre-built UI widgets for theme selection:

1. **ThemeSettingsWidget** - Full settings panel with radio buttons
2. **CompactThemeSelector** - Segmented button selector
3. **ThemeDropdown** - Dropdown menu selector
4. **ThemeToggleButton** - Icon button that cycles through modes

## Setup

The theme system is already configured in your app. Here's how it's wired together:

### 1. Service Registration (main.dart)

```dart
final _builder = Host.createApplicationBuilder()
  // ... other configuration
  // Register theme services
  ..services.addSingleton<ThemeService>((services) => ThemeService())
  ..services.addSingleton<ThemeNotifier>((services) => ThemeNotifier(
        services.getRequiredService<ThemeService>(),
      ))
```

### 2. Initialization (main.dart)

```dart
Future<void> main() async {
  // Initialize theme service before running the app
  final themeNotifier = host.services.getRequiredService<ThemeNotifier>();
  await themeNotifier.initialize();

  await host.run();
}
```

### 3. App Integration (app.dart)

```dart
@override
Widget build(BuildContext context) {
  final themeNotifier = services.getRequiredService<ThemeNotifier>();

  return ListenableBuilder(
    listenable: themeNotifier,
    builder: (context, _) {
      return MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeNotifier.themeMode,
        // ...
      );
    },
  );
}
```

## Usage Examples

### Add Theme Settings to a Page

```dart
import 'package:flutter_base/src/theme/theme_settings_widget.dart';

class SettingsPage extends StatelessWidget {
  final ServiceProvider services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ThemeSettingsWidget(
            themeNotifier: services.getRequiredService<ThemeNotifier>(),
          ),
          // ... other settings
        ],
      ),
    );
  }
}
```

### Add Theme Toggle to App Bar

```dart
import 'package:flutter_base/src/theme/theme_settings_widget.dart';

AppBar(
  title: Text('My App'),
  actions: [
    ThemeToggleButton(
      themeNotifier: services.getRequiredService<ThemeNotifier>(),
    ),
  ],
)
```

### Programmatically Change Theme

```dart
final themeNotifier = services.getRequiredService<ThemeNotifier>();

// Set to dark mode
await themeNotifier.setThemeMode(ThemeMode.dark);

// Set to light mode
await themeNotifier.setThemeMode(ThemeMode.light);

// Follow system theme
await themeNotifier.setThemeMode(ThemeMode.system);

// Reset to default (system)
await themeNotifier.resetToSystemDefault();
```

### Check Current Theme

```dart
final themeNotifier = services.getRequiredService<ThemeNotifier>();

if (themeNotifier.isDarkMode) {
  // Dark mode is active
}

if (themeNotifier.isSystemMode) {
  // Following system theme
}

// Or check the actual resolved theme
final isDark = Theme.of(context).brightness == Brightness.dark;
```

### Listen to Theme Changes

```dart
class MyWidget extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        // Widget rebuilds when theme changes
        return Container(
          color: themeNotifier.isDarkMode ? Colors.black : Colors.white,
          child: Text('Current mode: ${themeNotifier.themeMode.displayName}'),
        );
      },
    );
  }
}
```

## Theme Modes

### ThemeMode.system (Default)

- Follows the device's system theme setting
- Automatically switches between light and dark
- Respects user's system-wide theme preference
- **Best for accessibility** - honors user's OS-level choice

### ThemeMode.light

- Always uses the light theme
- Ignores system settings
- Good for users who prefer consistent light appearance

### ThemeMode.dark

- Always uses the dark theme
- Ignores system settings
- Good for users who prefer consistent dark appearance
- Reduces eye strain in low-light environments

## Customization Guide

### Change Theme Colors

Edit `app_theme.dart`:

```dart
// Option 1: Change seed color
static const Color _primarySeedColor = Colors.deepPurple;

// Option 2: Create custom ColorScheme
static ThemeData get lightTheme {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    // ... define all required colors
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
}
```

### Customize Component Themes

Add custom theme properties in `app_theme.dart`:

```dart
static ThemeData get lightTheme {
  // ... existing code

  return ThemeData(
    // ... existing properties

    // Customize text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    ),

    // Customize elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}
```

### Add Custom Theme Properties

For app-specific theme values, extend AppTheme:

```dart
class AppTheme {
  // ... existing code

  // Custom spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;

  // Custom dimensions
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
}
```

## Persistence Details

Theme preferences are stored in SharedPreferences with the key `theme_mode`.

**Stored values:**
- `"light"` → ThemeMode.light
- `"dark"` → ThemeMode.dark
- `"system"` → ThemeMode.system (default)

**Storage location:**
- iOS: `NSUserDefaults`
- Android: `SharedPreferences`
- Web: `localStorage`
- macOS: `NSUserDefaults`
- Linux: File in `~/.local/share/`
- Windows: Registry

## Testing

### Test Theme Switching

```dart
testWidgets('Theme changes when mode is updated', (tester) async {
  final themeService = ThemeService();
  final themeNotifier = ThemeNotifier(themeService);
  await themeNotifier.initialize();

  // Start with system mode
  expect(themeNotifier.themeMode, ThemeMode.system);

  // Change to dark
  await themeNotifier.setThemeMode(ThemeMode.dark);
  expect(themeNotifier.themeMode, ThemeMode.dark);

  // Verify persistence
  final saved = await themeService.getThemeMode();
  expect(saved, ThemeMode.dark);
});
```

## Troubleshooting

### Theme doesn't persist after restart

Make sure you're calling `themeNotifier.initialize()` in main.dart before running the app:

```dart
Future<void> main() async {
  final themeNotifier = host.services.getRequiredService<ThemeNotifier>();
  await themeNotifier.initialize(); // Don't forget this!
  await host.run();
}
```

### Theme changes don't update UI

Ensure you're using `ListenableBuilder` in app.dart:

```dart
ListenableBuilder(
  listenable: themeNotifier,
  builder: (context, _) {
    return MaterialApp.router(
      themeMode: themeNotifier.themeMode, // Must be inside ListenableBuilder
      // ...
    );
  },
)
```

### System theme doesn't work

- Verify device supports system theme (most modern devices do)
- Check that themeMode is set to `ThemeMode.system`
- Ensure both `theme` and `darkTheme` are provided to MaterialApp

## Additional Resources

- [Material Design 3 Theming](https://m3.material.io/styles/color/system/overview)
- [Flutter Theme Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [SharedPreferences Package](https://pub.dev/packages/shared_preferences)
