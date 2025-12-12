import 'dart:async';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Geolocator position data class.
class GeolocatorData {
  const GeolocatorData({
    required this.position,
    required this.serviceEnabled,
    required this.permission,
  });

  /// Current position
  final Position? position;

  /// Whether location services are enabled
  final bool serviceEnabled;

  /// Location permission status
  final LocationPermission permission;

  @override
  String toString() {
    return 'GeolocatorData(position: ${position != null ? '${position!.latitude}, ${position!.longitude}' : 'null'}, serviceEnabled: $serviceEnabled, permission: ${permission.name})';
  }
}

/// Options for configuring the Geolocator service.
class GeolocatorOptions {
  /// Whether to enable logging of geolocator initialization.
  bool? enableLogging = true;

  /// Whether to log position changes.
  bool? logPositionChanges = true;

  /// Desired location accuracy.
  LocationAccuracy? accuracy = LocationAccuracy.best;

  /// Minimum distance (in meters) before position updates.
  int? distanceFilter = 100;

  /// Whether to request permissions on startup.
  bool? requestPermissions = true;
}

extension GeolocatorServiceExtension on FlutterBuilder {
  ServiceCollection addLocationMonitor([
    void Function(GeolocatorOptions)? configureOptions,
  ]) {
    if (configureOptions != null) {
      services.configure<GeolocatorOptions>(
        GeolocatorOptions.new,
        (options) => configureOptions(options),
      );
    } else {
      services.configure<GeolocatorOptions>(GeolocatorOptions.new, (options) {
        options.enableLogging ??= true;
        options.logPositionChanges ??= false;
        options.accuracy ??= LocationAccuracy.best;
        options.distanceFilter ??= 10;
        options.requestPermissions ??= true;
      });
    }

    services
        .addSingleton<ValueNotifier<GeolocatorData?>>(
          (_) => ValueNotifier<GeolocatorData?>(null),
        )
        .addHostedService<GeolocatorBackgroundService>(
          (services) => GeolocatorBackgroundService(
            services.getRequiredService<ValueNotifier<GeolocatorData?>>(),
            services.getRequiredService<OptionsSnapshot<GeolocatorOptions>>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );

    return services;
  }
}

/// Background service that monitors location and makes it available via DI.
base class GeolocatorBackgroundService extends BackgroundService {
  GeolocatorBackgroundService(
    this._geolocatorNotifier,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('GeolocatorService');

  final ValueNotifier<GeolocatorData?> _geolocatorNotifier;
  final OptionsSnapshot<GeolocatorOptions> _options;
  final Logger _logger;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Position? _lastPosition;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    WidgetsFlutterBinding.ensureInitialized();

    _logger.logDebug('GeolocatorService is starting.');

    try {
      // Check and request permissions
      final permissionStatus = await _checkAndRequestPermissions();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Load initial position
      await _loadInitialPosition(permissionStatus, serviceEnabled);

      // Listen to service status changes
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
        (status) async {
          if (!stoppingToken.isCancellationRequested) {
            await _onServiceStatusChanged(status);
          }
        },
        onError: (error) {
          _logger.log<Exception>(
            logLevel: LogLevel.error,
            eventId: const EventId(4, 'ServiceStatusStreamError'),
            state: error as Exception,
            error: error,
            formatter: (state, err) => 'Service status stream error: $state',
          );
        },
      );

      // Listen to position changes if permissions are granted
      if (permissionStatus == LocationPermission.always ||
          permissionStatus == LocationPermission.whileInUse) {
        _positionSubscription =
            Geolocator.getPositionStream(
              locationSettings: LocationSettings(
                accuracy: _options.value!.accuracy!,
                distanceFilter: _options.value!.distanceFilter!,
              ),
            ).listen(
              (position) {
                if (!stoppingToken.isCancellationRequested) {
                  _onPositionChanged(position);
                }
              },
              onError: (error) {
                _logger.log<Exception>(
                  logLevel: LogLevel.error,
                  eventId: const EventId(5, 'PositionStreamError'),
                  state: error as Exception,
                  error: error,
                  formatter: (state, err) => 'Position stream error: $state',
                );
              },
            );
      }

      // Register cleanup on cancellation
      _cancellationRegistration = stoppingToken.register((_) {
        _positionSubscription?.cancel();
        _serviceStatusSubscription?.cancel();
      });
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(9, 'GeolocatorServiceExecutionFailed'),
        state: error,
        error: error,
        formatter: (state, err) =>
            'Geolocator service execution failed: $state',
      );
    }

    return Future.value();
  }

  Future<LocationPermission> _checkAndRequestPermissions() async {
    var permission = await Geolocator.checkPermission();

    if (_options.value!.requestPermissions! &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever)) {
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _logger.log<LocationPermission>(
          logLevel: LogLevel.warning,
          eventId: const EventId(2, 'LocationPermissionDenied'),
          state: permission,
          formatter: (state, _) => 'Location permission denied: ${state.name}',
        );
      }
    }

    return permission;
  }

  Future<void> _loadInitialPosition(
    LocationPermission permission,
    bool serviceEnabled,
  ) async {
    Position? position;

    if (serviceEnabled &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse)) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: _options.value!.accuracy!,
          ),
        );
        _lastPosition = position;
      } on Exception catch (error) {
        // On macOS and iOS, the initial position request may fail even after
        // granting permission because the system is still processing the permission.
        // The position stream will start working once fully initialized.
        // Only log as warning if we expect to have permission.
        _logger.log<Exception>(
          logLevel: LogLevel.warning,
          eventId: const EventId(3, 'InitialPositionUnavailable'),
          state: error,
          error: error,
          formatter: (state, err) =>
              'Initial position unavailable (will retry via stream): ${error.toString().split('\n').first}',
        );
      }
    }

    final data = GeolocatorData(
      position: position,
      serviceEnabled: serviceEnabled,
      permission: permission,
    );

    _geolocatorNotifier.value = data;

    if (_options.value!.enableLogging!) {
      _logger.log<GeolocatorData>(
        logLevel: LogLevel.debug,
        eventId: const EventId(1, 'GeolocatorDataLoaded'),
        state: data,
        formatter: (state, _) => position != null
            ? 'Initial position: ${position.latitude}, ${position.longitude}'
            : 'Waiting for position updates (serviceEnabled=$serviceEnabled, permission=${permission.name})',
      );
    }
  }

  void _onPositionChanged(Position position) {
    final currentData = _geolocatorNotifier.value;

    final data = GeolocatorData(
      position: position,
      serviceEnabled: currentData?.serviceEnabled ?? true,
      permission: currentData?.permission ?? LocationPermission.whileInUse,
    );

    _geolocatorNotifier.value = data;

    if (_options.value!.logPositionChanges!) {
      final lastPos = _lastPosition;
      _logger.log<GeolocatorData>(
        logLevel: LogLevel.trace,
        eventId: const EventId(6, 'PositionChanged'),
        state: data,
        formatter: (state, _) => lastPos == null
            ? 'Position: ${position.latitude}, ${position.longitude}'
            : 'Position changed: ${lastPos.latitude}, ${lastPos.longitude} → ${position.latitude}, ${position.longitude}',
      );
    }

    _lastPosition = position;
  }

  Future<void> _onServiceStatusChanged(ServiceStatus status) async {
    final serviceEnabled = status == ServiceStatus.enabled;
    final currentData = _geolocatorNotifier.value;

    final data = GeolocatorData(
      position: currentData?.position,
      serviceEnabled: serviceEnabled,
      permission: currentData?.permission ?? LocationPermission.denied,
    );

    _geolocatorNotifier.value = data;

    _logger.log<ServiceStatus>(
      logLevel: LogLevel.debug,
      eventId: const EventId(7, 'ServiceStatusChanged'),
      state: status,
      formatter: (state, _) => 'Location service status changed: ${state.name}',
    );
  }

  @override
  Future<void> dispose() async {
    _cancellationRegistration?.dispose();
    await _positionSubscription?.cancel();
    await _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}
