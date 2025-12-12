import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/foundation.dart';
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
/// // Access brightness from DI
/// final brightnessNotifier = services.getRequiredService<ValueNotifier<Brightness>>();
/// brightnessNotifier.addListener(() {
///   print('System brightness changed to: ${brightnessNotifier.value}');
/// });
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

/// Background service that tracks platform brightness changes and pushes updates into DI.
base class PlatformBrightnessBackgroundService extends BackgroundService {
  PlatformBrightnessBackgroundService(
    this._brightnessNotifier,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('PlatformBrightnessService');

  final ValueNotifier<Brightness> _brightnessNotifier;
  final Logger _logger;
  VoidCallback? _listener;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    WidgetsFlutterBinding.ensureInitialized();

    _logger.logDebug('PlatformBrightnessService is starting.');

    _updateInitialBrightness();

    // Set up listener for brightness changes
    _listener = () {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      _handleUpdate(brightness);
    };

    PlatformDispatcher.instance.onPlatformBrightnessChanged = _listener;

    _cancellationRegistration = stoppingToken.register((_) => _cleanup());

    return Future.value();
  }

  void _updateInitialBrightness() {
    try {
      final initial = PlatformDispatcher.instance.platformBrightness;
      _handleUpdate(initial);
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.warning,
        eventId: const EventId(3, 'PlatformBrightnessInitialCheckFailed'),
        state: error,
        error: error,
        formatter: (state, err) =>
            'Failed to query platform brightness: $state',
      );
    }
  }

  void _handleUpdate(Brightness brightness) {
    _brightnessNotifier.value = brightness;
    _logger.log<Brightness>(
      logLevel: LogLevel.debug,
      eventId: const EventId(1, 'PlatformBrightnessChanged'),
      state: brightness,
      formatter: (state, _) => 'Platform brightness changed: ${state.name}',
    );
  }

  void _cleanup() {
    if (_listener != null) {
      PlatformDispatcher.instance.onPlatformBrightnessChanged = null;
      _listener = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    _cancellationRegistration?.dispose();
    super.dispose();
  }
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
  ServiceCollection addBrightnessMonitor() {
    return services
      ..addSingleton<ValueNotifier<Brightness>>(
        (_) => ValueNotifier<Brightness>(Brightness.light),
      )
      ..addHostedService<PlatformBrightnessBackgroundService>(
        (services) => PlatformBrightnessBackgroundService(
          services.getRequiredService<ValueNotifier<Brightness>>(),
          services.getRequiredService<LoggerFactory>(),
        ),
      )
      ..addSingleton<RegisteredWidgetFactory>(
        (_) =>
            (sp, child) => PlatformBrightnessListener(child: child),
      );
  }
}
