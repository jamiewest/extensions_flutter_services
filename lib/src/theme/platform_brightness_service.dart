import 'dart:ui';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';

/// Service that monitors platform brightness changes.
///
/// This service listens to the platform's brightness setting (light/dark mode)
/// and provides callbacks when the system theme changes. This is useful for:
/// - Detecting when the user switches between light/dark mode in system settings
/// - Automatically updating UI when automatic theme switching occurs (e.g., sunset)
/// - Responding to iOS/Android system theme changes
///
/// ## Usage
///
/// ```dart
/// final service = PlatformBrightnessService();
/// service.initialize(
///   onBrightnessChanged: (brightness) {
///     print('System brightness changed to: $brightness');
///     if (themeNotifier.isSystemMode) {
///       // Theme will automatically update via MaterialApp
///     }
///   },
/// );
/// ```
///
/// ## How It Works
///
/// The service uses [PlatformDispatcher.onPlatformBrightnessChanged] to detect
/// when the system brightness changes. This callback is triggered when:
/// - User manually changes system theme in device settings
/// - Automatic theme switching occurs (e.g., Dark Mode scheduled times)
/// - Device enters/exits dark mode based on time of day
///
/// ## Integration with ThemeNotifier
///
/// When using `ThemeMode.system`, Flutter automatically responds to platform
/// brightness changes. This service provides additional hooks for logging,
/// analytics, or custom behavior when the system theme changes.
class PlatformBrightnessService {
  VoidCallback? _listener;
  void Function(Brightness)? _onBrightnessChanged;

  /// The current platform brightness.
  ///
  /// This reflects the system-wide brightness setting, not the app's theme mode.
  Brightness get currentBrightness {
    return PlatformDispatcher.instance.platformBrightness;
  }

  /// Initializes the service and starts listening for brightness changes.
  ///
  /// [onBrightnessChanged] will be called whenever the platform brightness changes.
  void initialize({required void Function(Brightness) onBrightnessChanged}) {
    _onBrightnessChanged = onBrightnessChanged;

    // Set up listener for brightness changes
    _listener = () {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      _onBrightnessChanged?.call(brightness);
    };

    PlatformDispatcher.instance.onPlatformBrightnessChanged = _listener;

    // Call immediately with current brightness
    _onBrightnessChanged?.call(currentBrightness);
  }

  /// Disposes the service and removes the listener.
  void dispose() {
    if (_listener != null) {
      PlatformDispatcher.instance.onPlatformBrightnessChanged = null;
      _listener = null;
    }
    _onBrightnessChanged = null;
  }

  /// Returns true if the current platform brightness is dark.
  bool get isDarkMode => currentBrightness == Brightness.dark;

  /// Returns true if the current platform brightness is light.
  bool get isLightMode => currentBrightness == Brightness.light;
}

/// Widget that provides platform brightness change notifications to descendants.
///
/// This is an alternative to using [PlatformBrightnessService] directly.
/// It rebuilds whenever the platform brightness changes.
///
/// ## Usage
///
/// ```dart
/// PlatformBrightnessListener(
///   onBrightnessChanged: (brightness) {
///     print('Platform brightness: $brightness');
///   },
///   child: MyApp(),
/// )
/// ```
class PlatformBrightnessListener extends StatefulWidget {
  const PlatformBrightnessListener({
    super.key,
    required this.child,
    this.onBrightnessChanged,
  });

  final Widget child;
  final void Function(Brightness)? onBrightnessChanged;

  @override
  State<PlatformBrightnessListener> createState() =>
      _PlatformBrightnessListenerState();
}

class _PlatformBrightnessListenerState extends State<PlatformBrightnessListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Call immediately with current brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onBrightnessChanged?.call(
        PlatformDispatcher.instance.platformBrightness,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    widget.onBrightnessChanged?.call(
      PlatformDispatcher.instance.platformBrightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension on [BuildContext] to easily access platform brightness.
extension PlatformBrightnessBuildContextExtension on BuildContext {
  /// Returns the current platform brightness (system-wide setting).
  ///
  /// This is different from `Theme.of(context).brightness` which returns
  /// the app's current theme brightness.
  Brightness get platformBrightness {
    return MediaQuery.platformBrightnessOf(this);
  }

  /// Returns true if the platform is in dark mode.
  bool get isPlatformDarkMode {
    return platformBrightness == Brightness.dark;
  }

  /// Returns true if the platform is in light mode.
  bool get isPlatformLightMode {
    return platformBrightness == Brightness.light;
  }
}

extension PlatformBrightnessFlutterBuilderExtension on FlutterBuilder {
  FlutterBuilder addPlatformBrightnessService() {
    services.addSingleton<PlatformBrightnessService>(
      (services) => PlatformBrightnessService(),
    );

    return this;
  }
}
