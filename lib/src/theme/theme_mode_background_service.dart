import 'dart:async';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/material.dart';

import 'theme_mode_service.dart';

/// Background service that manages theme mode and automatically
/// responds to platform brightness changes.
///
/// This service:
/// - Loads the saved theme preference on startup
/// - Updates the theme mode ValueNotifier
/// - Listens to platform brightness changes
/// - Persists theme mode changes
base class ThemeModeBackgroundService extends BackgroundService {
  ThemeModeBackgroundService(
    this._themeModeNotifier,
    this._platformBrightnessNotifier,
    this._themeModeService,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('ThemeModeBackgroundService');

  final ValueNotifier<ThemeMode> _themeModeNotifier;
  final ValueNotifier<Brightness> _platformBrightnessNotifier;
  final ThemeModeService _themeModeService;
  final Logger _logger;

  Brightness _platformBrightness = Brightness.light;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    _logger.logDebug('Starting Theme service.');

    // Load saved theme preference
    await _loadThemeMode();

    // Set up platform brightness monitoring
    _platformBrightness = _platformBrightnessNotifier.value;
    _platformBrightnessNotifier.addListener(_onPlatformBrightnessChanged);

    _logger.logInformation(
      'Theme service initialized with mode: ${_themeModeNotifier.value.name}, '
      'platform brightness: ${_platformBrightness.name}',
    );

    // Register cleanup on cancellation
    _cancellationRegistration = stoppingToken.register((_) {
      _platformBrightnessNotifier.removeListener(_onPlatformBrightnessChanged);
    });

    return Future.value();
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeMode = await _themeModeService.getThemeMode();
      _themeModeNotifier.value = themeMode;

      _logger.log<ThemeMode>(
        logLevel: LogLevel.information,
        eventId: const EventId(1, 'ThemeModeLoaded'),
        state: themeMode,
        formatter: (state, _) => 'Loaded theme mode: ${state.name}',
      );
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(2, 'ThemeModeLoadFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to load theme mode: $state',
      );
      // Default to system theme if loading fails
      _themeModeNotifier.value = ThemeMode.system;
    }
  }

  void _onPlatformBrightnessChanged() {
    final newBrightness = _platformBrightnessNotifier.value;
    if (_platformBrightness == newBrightness) return;

    _platformBrightness = newBrightness;
    _logger.log<Brightness>(
      logLevel: LogLevel.information,
      eventId: const EventId(3, 'PlatformBrightnessChanged'),
      state: newBrightness,
      formatter: (state, _) => 'Platform brightness changed to: ${state.name}',
    );

    // If we're in system mode, the theme will automatically update
    // because MaterialApp listens to the platform brightness
    if (_themeModeNotifier.value == ThemeMode.system) {
      _logger.logDebug(
        'Theme mode is system, UI will update to match platform brightness',
      );
    }
  }

  @override
  Future<void> dispose() async {
    _logger.logTrace('Disposing Theme service.');
    _platformBrightnessNotifier.removeListener(_onPlatformBrightnessChanged);
    _cancellationRegistration?.dispose();
    super.dispose();
  }
}
