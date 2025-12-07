import 'dart:async';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Network information data class.
class NetworkInfoData {
  const NetworkInfoData({
    this.wifiName,
    this.wifiBSSID,
    this.wifiIP,
    this.wifiIPv6,
    this.wifiGatewayIP,
    this.wifiSubmask,
    this.wifiBroadcast,
  });

  /// WiFi network name (SSID)
  final String? wifiName;

  /// WiFi MAC address (BSSID)
  final String? wifiBSSID;

  /// WiFi IPv4 address
  final String? wifiIP;

  /// WiFi IPv6 address
  final String? wifiIPv6;

  /// WiFi gateway IP address
  final String? wifiGatewayIP;

  /// WiFi subnet mask
  final String? wifiSubmask;

  /// WiFi broadcast address
  final String? wifiBroadcast;

  @override
  String toString() {
    return 'NetworkInfoData(name: $wifiName, IP: $wifiIP, gateway: $wifiGatewayIP)';
  }
}

/// Options for configuring the NetworkInfo service.
class NetworkInfoOptions {
  const NetworkInfoOptions({
    this.enableLogging = true,
    this.logDetailedInfo = false,
    this.refreshInterval,
  });

  /// Whether to enable logging of network info initialization.
  final bool enableLogging;

  /// Whether to log detailed network information (BSSID, subnet, etc).
  final bool logDetailedInfo;

  /// Optional interval to refresh network info periodically.
  final Duration? refreshInterval;
}

extension NetworkInfoServiceExtension on FlutterBuilder {
  ServiceCollection addNetworkInfo([
    void Function(NetworkInfoOptions)? configure,
  ]) {
    final options = NetworkInfoOptions();
    if (configure != null) {
      // Since NetworkInfoOptions is immutable, we need a builder pattern
      final builder = _NetworkInfoOptionsBuilder();
      configure(builder._options);
      return _addNetworkInfoWithOptions(builder._options, services);
    }
    return _addNetworkInfoWithOptions(options, services);
  }

  ServiceCollection _addNetworkInfoWithOptions(
    NetworkInfoOptions options,
    ServiceCollection services,
  ) {
    return services
        .addSingleton<NetworkInfoOptions>((_) => options)
        .addSingleton<ValueNotifier<NetworkInfoData?>>(
          (_) => ValueNotifier<NetworkInfoData?>(null),
        )
        .addHostedService<NetworkInfoBackgroundService>(
          (services) => NetworkInfoBackgroundService(
            services.getRequiredService<ValueNotifier<NetworkInfoData?>>(),
            services.getRequiredService<NetworkInfoOptions>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

class _NetworkInfoOptionsBuilder {
  NetworkInfoOptions _options = const NetworkInfoOptions();

  void setEnableLogging(bool enableLogging) {
    _options = NetworkInfoOptions(
      enableLogging: enableLogging,
      logDetailedInfo: _options.logDetailedInfo,
      refreshInterval: _options.refreshInterval,
    );
  }

  void setLogDetailedInfo(bool logDetailedInfo) {
    _options = NetworkInfoOptions(
      enableLogging: _options.enableLogging,
      logDetailedInfo: logDetailedInfo,
      refreshInterval: _options.refreshInterval,
    );
  }

  void setRefreshInterval(Duration? refreshInterval) {
    _options = NetworkInfoOptions(
      enableLogging: _options.enableLogging,
      logDetailedInfo: _options.logDetailedInfo,
      refreshInterval: refreshInterval,
    );
  }
}

/// Background service that loads NetworkInfo and makes it available via DI.
base class NetworkInfoBackgroundService extends BackgroundService {
  NetworkInfoBackgroundService(
    this._networkInfoNotifier,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('NetworkInfoBackgroundService');

  final ValueNotifier<NetworkInfoData?> _networkInfoNotifier;
  final NetworkInfoOptions _options;
  final Logger _logger;
  final _networkInfo = NetworkInfo();
  Timer? _refreshTimer;
  CancellationTokenRegistration? _cancellationRegistration;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    // Load network info initially
    await _loadNetworkInfo();

    // Set up periodic refresh if configured
    if (_options.refreshInterval != null) {
      _refreshTimer = Timer.periodic(_options.refreshInterval!, (_) async {
        if (!stoppingToken.isCancellationRequested) {
          await _loadNetworkInfo();
        }
      });
    }

    // Register cleanup on cancellation
    _cancellationRegistration = stoppingToken.register((_) {
      _refreshTimer?.cancel();
    });

    return Future.value();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiBSSID = await _networkInfo.getWifiBSSID();
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiIPv6 = await _networkInfo.getWifiIPv6();
      final wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
      final wifiSubmask = await _networkInfo.getWifiSubmask();
      final wifiBroadcast = await _networkInfo.getWifiBroadcast();

      final info = NetworkInfoData(
        wifiName: wifiName,
        wifiBSSID: wifiBSSID,
        wifiIP: wifiIP,
        wifiIPv6: wifiIPv6,
        wifiGatewayIP: wifiGatewayIP,
        wifiSubmask: wifiSubmask,
        wifiBroadcast: wifiBroadcast,
      );

      _networkInfoNotifier.value = info;

      if (_options.enableLogging) {
        _logger.log<NetworkInfoData>(
          logLevel: LogLevel.information,
          eventId: const EventId(1, 'NetworkInfoLoaded'),
          state: info,
          formatter: (state, _) =>
              'NetworkInfo loaded: ${state.wifiName ?? "No WiFi"} (${state.wifiIP ?? "No IP"})',
        );

        if (_options.logDetailedInfo) {
          _logger.log<NetworkInfoData>(
            logLevel: LogLevel.debug,
            eventId: const EventId(2, 'NetworkInfoDetails'),
            state: info,
            formatter: (state, _) =>
                'Network details - BSSID: ${state.wifiBSSID}, '
                'Gateway: ${state.wifiGatewayIP}, '
                'Submask: ${state.wifiSubmask}, '
                'Broadcast: ${state.wifiBroadcast}, '
                'IPv6: ${state.wifiIPv6}',
          );
        }
      }
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(3, 'NetworkInfoLoadFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to load NetworkInfo: $state',
      );
    }
  }

  @override
  Future<void> dispose() async {
    _cancellationRegistration?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
