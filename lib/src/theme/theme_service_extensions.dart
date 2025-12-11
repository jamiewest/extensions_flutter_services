import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/material.dart';

import 'theme_mode_background_service.dart';
import 'theme_mode_service.dart';

extension ThemeServiceExtensions on FlutterBuilder {
  /// Adds theme management services to the application.
  ///
  /// This registers:
  /// - [ValueNotifier<ThemeMode>] - The current theme mode
  /// - [ThemeService] - Persistence layer for theme preferences
  /// - [ThemeBackgroundService] - Background service that manages theme state
  /// - A setter function for updating the theme mode
  ///
  /// ## Usage
  ///
  /// ```dart
  /// // Register the service
  /// builder.addThemeService();
  ///
  /// // Access the theme mode in your app
  /// final themeModeNotifier = services.getRequiredService<ValueNotifier<ThemeMode>>();
  ///
  /// MaterialApp(
  ///   themeMode: themeModeNotifier.value,
  ///   // ...
  /// )
  ///
  /// // Listen to theme changes
  /// ValueListenableBuilder<ThemeMode>(
  ///   valueListenable: themeModeNotifier,
  ///   builder: (context, mode, _) => Text('Current theme: ${mode.name}'),
  /// )
  ///
  /// // Update the theme
  /// final setTheme = services.getRequiredService<void Function(ThemeMode)>();
  /// setTheme(ThemeMode.dark);
  /// ```
  FlutterBuilder addThemeService() {
    services
        .addSingleton<ThemeModeService>((_) => ThemeModeService())
        .addSingleton<ValueNotifier<ThemeMode>>(
          (_) => ValueNotifier<ThemeMode>(ThemeMode.system),
        )
        .addHostedService<ThemeModeBackgroundService>(
          (services) => ThemeModeBackgroundService(
            services.getRequiredService<ValueNotifier<ThemeMode>>(),
            services.getRequiredService<ValueNotifier<Brightness>>(),
            services.getRequiredService<ThemeModeService>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        )
        .addSingleton<void Function(ThemeMode)>((services) {
          final notifier = services
              .getRequiredService<ValueNotifier<ThemeMode>>();
          final themeService = services.getRequiredService<ThemeModeService>();
          final loggerFactory = services.getRequiredService<LoggerFactory>();
          final logger = loggerFactory.createLogger('ThemeSetter');

          return (ThemeMode mode) {
            if (notifier.value == mode) return;

            logger.log<ThemeMode>(
              logLevel: LogLevel.information,
              eventId: const EventId(1, 'ThemeModeChanged'),
              state: mode,
              formatter: (state, _) => 'Changing theme mode to: ${state.name}',
            );

            notifier.value = mode;

            // Persist asynchronously
            themeService
                .saveThemeMode(mode)
                .then((success) {
                  if (success) {
                    logger.logDebug('Theme mode saved successfully');
                  } else {
                    logger.logWarning('Failed to save theme mode');
                  }
                })
                .catchError((error) {
                  logger.log<dynamic>(
                    logLevel: LogLevel.error,
                    eventId: const EventId(2, 'ThemeModeSaveFailed'),
                    state: error,
                    error: error as Exception,
                    formatter: (state, err) =>
                        'Error saving theme mode: $state',
                  );
                });
          };
        });

    return this;
  }
}
