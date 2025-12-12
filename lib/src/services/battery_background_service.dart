import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';

/// Battery information data class.
class BatteryInfoData {
  const BatteryInfoData({
    required this.level,
    required this.state,
    required this.isInBatterySaveMode,
  });

  /// Battery level (0-100)
  final int level;

  /// Battery state (full, charging, discharging, etc.)
  final BatteryState state;

  /// Whether the device is in battery save mode
  final bool isInBatterySaveMode;

  @override
  String toString() {
    return 'BatteryInfoData(level: $level%, state: $state, saveMode: $isInBatterySaveMode)';
  }
}

/// Options for configuring the Battery service.
class BatteryOptions {
  const BatteryOptions({
    this.enableLogging = true,
    this.logStateChanges = true,
    this.logLevelChanges = false,
    this.pollInterval,
  });

  /// Whether to enable logging of battery info initialization.
  final bool enableLogging;

  /// Whether to log battery state changes (charging, discharging, full).
  final bool logStateChanges;

  /// Whether to log battery level changes.
  final bool logLevelChanges;

  /// Optional interval to poll battery level (in addition to state stream).
  final Duration? pollInterval;
}

extension BatteryServiceExtension on FlutterBuilder {
  ServiceCollection addBatteryMonitor([
    void Function(BatteryOptions)? configure,
  ]) {
    final options = BatteryOptions();
    if (configure != null) {
      // Since BatteryOptions is immutable, we need a builder pattern
      final builder = _BatteryOptionsBuilder();
      configure(builder._options);
      return _addBatteryWithOptions(builder._options);
    }
    return _addBatteryWithOptions(options);
  }

  ServiceCollection _addBatteryWithOptions(BatteryOptions options) {
    return services
        .addSingleton<BatteryOptions>((_) => options)
        .addSingleton<ValueNotifier<BatteryInfoData?>>(
          (_) => ValueNotifier<BatteryInfoData?>(null),
        )
        .addHostedService<BatteryBackgroundService>(
          (services) => BatteryBackgroundService(
            services.getRequiredService<ValueNotifier<BatteryInfoData?>>(),
            services.getRequiredService<BatteryOptions>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

class _BatteryOptionsBuilder {
  BatteryOptions _options = const BatteryOptions();

  void setEnableLogging(bool enableLogging) {
    _options = BatteryOptions(
      enableLogging: enableLogging,
      logStateChanges: _options.logStateChanges,
      logLevelChanges: _options.logLevelChanges,
      pollInterval: _options.pollInterval,
    );
  }

  void setLogStateChanges(bool logStateChanges) {
    _options = BatteryOptions(
      enableLogging: _options.enableLogging,
      logStateChanges: logStateChanges,
      logLevelChanges: _options.logLevelChanges,
      pollInterval: _options.pollInterval,
    );
  }

  void setLogLevelChanges(bool logLevelChanges) {
    _options = BatteryOptions(
      enableLogging: _options.enableLogging,
      logStateChanges: _options.logStateChanges,
      logLevelChanges: logLevelChanges,
      pollInterval: _options.pollInterval,
    );
  }

  void setPollInterval(Duration? pollInterval) {
    _options = BatteryOptions(
      enableLogging: _options.enableLogging,
      logStateChanges: _options.logStateChanges,
      logLevelChanges: _options.logLevelChanges,
      pollInterval: pollInterval,
    );
  }
}

/// Background service that monitors Battery info and makes it available via DI.
base class BatteryBackgroundService extends BackgroundService {
  BatteryBackgroundService(
    this._batteryInfoNotifier,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('BatteryService');

  final ValueNotifier<BatteryInfoData?> _batteryInfoNotifier;
  final BatteryOptions _options;
  final Logger _logger;
  final _battery = Battery();
  StreamSubscription<BatteryState>? _stateSubscription;
  Timer? _pollTimer;
  BatteryState? _lastState;
  int? _lastLevel;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    WidgetsFlutterBinding.ensureInitialized();

    _logger.logDebug('BatteryService is starting.');

    try {
      // Load battery info initially
      await _loadBatteryInfo();

      // Listen to battery state changes
      _stateSubscription = _battery.onBatteryStateChanged.listen(
        (state) async {
          if (!stoppingToken.isCancellationRequested) {
            await _onBatteryStateChanged(state);
          }
        },
        onError: (error) {
          _logger.log<Exception>(
            logLevel: LogLevel.error,
            eventId: const EventId(4, 'BatteryStateStreamError'),
            state: error as Exception,
            error: error,
            formatter: (state, err) => 'Battery state stream error: $state',
          );
        },
      );

      // Set up periodic polling if configured
      if (_options.pollInterval != null) {
        _pollTimer = Timer.periodic(_options.pollInterval!, (_) async {
          if (!stoppingToken.isCancellationRequested) {
            await _loadBatteryInfo();
          }
        });
      }

      // Register cleanup on cancellation
      _cancellationRegistration = stoppingToken.register((_) {
        _stateSubscription?.cancel();
        _pollTimer?.cancel();
      });
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(9, 'BatteryServiceExecutionFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Battery service execution failed: $state',
      );
    }

    return Future.value();
  }

  Future<void> _loadBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      // isInBatterySaveMode may not be supported on all platforms
      bool isInBatterySaveMode = false;
      try {
        isInBatterySaveMode = await _battery.isInBatterySaveMode;
      } catch (_) {
        // Ignore if not supported on this platform
      }

      final info = BatteryInfoData(
        level: level,
        state: state,
        isInBatterySaveMode: isInBatterySaveMode,
      );

      _batteryInfoNotifier.value = info;

      // Log level changes if enabled
      if (_options.logLevelChanges &&
          _lastLevel != null &&
          _lastLevel != level) {
        _logger.log<BatteryInfoData>(
          logLevel: LogLevel.trace,
          eventId: const EventId(5, 'BatteryLevelChanged'),
          state: info,
          formatter: (state, _) =>
              'Battery level changed: $_lastLevel% → ${state.level}%',
        );
      }

      _lastLevel = level;

      if (_options.enableLogging && _lastState == null) {
        _logger.log<BatteryInfoData>(
          logLevel: LogLevel.debug,
          eventId: const EventId(1, 'BatteryInfoLoaded'),
          state: info,
          formatter: (state, _) => 'Battery level is ${state.level}%.',
        );
      }
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(3, 'BatteryInfoLoadFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to load battery info: $state',
      );
    }
  }

  Future<void> _onBatteryStateChanged(BatteryState state) async {
    try {
      final level = await _battery.batteryLevel;

      // isInBatterySaveMode may not be supported on all platforms
      bool isInBatterySaveMode = false;
      try {
        isInBatterySaveMode = await _battery.isInBatterySaveMode;
      } catch (_) {
        // Ignore if not supported on this platform
      }

      final info = BatteryInfoData(
        level: level,
        state: state,
        isInBatterySaveMode: isInBatterySaveMode,
      );

      _batteryInfoNotifier.value = info;

      if (_options.logStateChanges && _lastState != state) {
        _logger.log<BatteryInfoData>(
          logLevel: LogLevel.trace,
          eventId: const EventId(2, 'BatteryStateChanged'),
          state: info,
          formatter: (state, _) => _lastState == null
              ? 'Battery state: ${state.state.name} (${state.level}%)'
              : 'Battery state changed: ${_lastState!.name} → ${state.state.name} (${state.level}%)',
        );
      }

      _lastState = state;
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(6, 'BatteryStateChangeHandlingFailed'),
        state: error,
        error: error,
        formatter: (state, err) =>
            'Failed to handle battery state change: $state',
      );
    }
  }

  @override
  Future<void> dispose() async {
    _cancellationRegistration?.dispose();
    await _stateSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
