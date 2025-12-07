import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/foundation.dart';

extension ConnectivityServiceExtension on FlutterBuilder {
  ServiceCollection addConnectivityService() {
    return services
        .addSingleton<Connectivity>((services) => Connectivity())
        .addSingleton<ValueNotifier<List<ConnectivityResult>>>(
          (_) => ValueNotifier<List<ConnectivityResult>>(<ConnectivityResult>[
            ConnectivityResult.none,
          ]),
        )
        .addHostedService<ConnectivityBackgroundService>(
          (services) => ConnectivityBackgroundService(
            services.getRequiredService<Connectivity>(),
            services
                .getRequiredService<ValueNotifier<List<ConnectivityResult>>>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

/// Background service that tracks connectivity changes and pushes updates into DI.
base class ConnectivityBackgroundService extends BackgroundService {
  ConnectivityBackgroundService(
    this._connectivity,
    this._connectivityStatus,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('ConnectivityBackgroundService');

  final Connectivity _connectivity;
  final ValueNotifier<List<ConnectivityResult>> _connectivityStatus;
  final Logger _logger;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    await _updateInitialStatus();

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _logger.log<Object>(
          logLevel: LogLevel.error,
          eventId: const EventId(2, 'ConnectivityStreamError'),
          state: error,
          error: stackTrace,
          formatter: (state, err) => 'Connectivity stream error: $state',
        );
      },
    );

    _cancellationRegistration = stoppingToken.register(
      (_) => _subscription?.cancel(),
    );

    return Future.value();
  }

  Future<void> _updateInitialStatus() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _handleUpdate(initial);
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.warning,
        eventId: const EventId(3, 'ConnectivityInitialCheckFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to query connectivity: $state',
      );
    }
  }

  void _handleUpdate(List<ConnectivityResult> results) {
    final normalized = results.isEmpty
        ? <ConnectivityResult>[ConnectivityResult.none]
        : results;
    _connectivityStatus.value = normalized;
    _logger.log<List<ConnectivityResult>>(
      logLevel: LogLevel.debug,
      eventId: const EventId(1, 'ConnectivityChanged'),
      state: normalized,
      formatter: (state, _) =>
          'Connectivity changed: ${state.map((s) => s.name).join(', ')}',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cancellationRegistration?.dispose();
    super.dispose();
  }
}
