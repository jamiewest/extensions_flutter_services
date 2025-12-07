import 'package:flutter/material.dart';
import 'theme_mode_extensions.dart';
import 'theme_notifier.dart';

/// A widget that displays theme selection options.
///
/// This widget provides a UI for users to choose between light, dark,
/// and system theme modes. It uses [ThemeNotifier] to manage and persist
/// the theme preference.
///
/// ## Usage
///
/// ```dart
/// // In a widget with access to services
/// ThemeSettingsWidget(
///   themeNotifier: services.getRequiredService<ThemeNotifier>(),
/// )
/// ```
///
/// ## Example in a Settings Page
///
/// ```dart
/// class SettingsPage extends StatelessWidget {
///   final ServiceProvider services;
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Settings')),
///       body: ListView(
///         children: [
///           ThemeSettingsWidget(
///             themeNotifier: services.getRequiredService<ThemeNotifier>(),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
class ThemeSettingsWidget extends StatelessWidget {
  const ThemeSettingsWidget({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...ThemeMode.values.map((mode) {
              final isSelected = themeNotifier.themeMode == mode;
              return ListTile(
                leading: Radio<ThemeMode>(
                  value: mode,
                  groupValue: themeNotifier.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeNotifier.setThemeMode(value);
                    }
                  },
                ),
                title: Text(mode.displayName),
                subtitle: Text(mode.description),
                trailing: Icon(
                  mode.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => themeNotifier.setThemeMode(mode),
              );
            }),
          ],
        );
      },
    );
  }
}

/// A compact theme selector widget that displays as a segmented button.
///
/// This provides a more compact alternative to [ThemeSettingsWidget],
/// useful for toolbars or compact settings areas.
class CompactThemeSelector extends StatelessWidget {
  const CompactThemeSelector({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return SegmentedButton<ThemeMode>(
          segments: ThemeMode.values
              .map(
                (mode) => ButtonSegment<ThemeMode>(
                  value: mode,
                  icon: Icon(mode.icon),
                  label: Text(mode.displayName),
                ),
              )
              .toList(),
          selected: {themeNotifier.themeMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            themeNotifier.setThemeMode(newSelection.first);
          },
        );
      },
    );
  }
}

/// A simple dropdown for theme selection.
///
/// Useful for inline theme selection in forms or settings.
class ThemeDropdown extends StatelessWidget {
  const ThemeDropdown({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return DropdownButton<ThemeMode>(
          value: themeNotifier.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeNotifier.setThemeMode(value);
            }
          },
          items: ThemeMode.values.map((mode) {
            return DropdownMenuItem<ThemeMode>(
              value: mode,
              child: Row(
                children: [
                  Icon(mode.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(mode.displayName),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// An icon button that cycles through theme modes.
///
/// Useful for app bars or floating action buttons.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  void _cycleTheme() {
    final currentMode = themeNotifier.themeMode;
    final nextMode = switch (currentMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    themeNotifier.setThemeMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return IconButton(
          icon: Icon(themeNotifier.themeMode.icon),
          onPressed: _cycleTheme,
          tooltip: 'Change theme (${themeNotifier.themeMode.displayName})',
        );
      },
    );
  }
}
