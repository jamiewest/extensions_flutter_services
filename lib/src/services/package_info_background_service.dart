import 'dart:async';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Options for configuring the PackageInfo service.
class PackageInfoOptions {
  const PackageInfoOptions({
    this.enableLogging = true,
    this.logBuildInfo = false,
  });

  /// Whether to enable logging of package info initialization.
  final bool enableLogging;

  /// Whether to log detailed build information (build number, signature, etc).
  final bool logBuildInfo;
}

extension PackageInfoServiceExtension on FlutterBuilder {
  ServiceCollection addPackageInformation([
    void Function(PackageInfoOptions)? configure,
  ]) {
    final options = PackageInfoOptions();
    if (configure != null) {
      // Since PackageInfoOptions is immutable, we need a builder pattern
      final builder = _PackageInfoOptionsBuilder();
      configure(builder._options);
      return _addPackageInfoWithOptions(builder._options, services);
    }
    return _addPackageInfoWithOptions(options, services);
  }

  ServiceCollection _addPackageInfoWithOptions(
    PackageInfoOptions options,
    ServiceCollection services,
  ) {
    return services
        .addSingleton<PackageInfoOptions>((_) => options)
        .addSingleton<ValueNotifier<PackageInfo?>>(
          (_) => ValueNotifier<PackageInfo?>(null),
        )
        .addHostedService<PackageInfoBackgroundService>(
          (services) => PackageInfoBackgroundService(
            services.getRequiredService<ValueNotifier<PackageInfo?>>(),
            services.getRequiredService<PackageInfoOptions>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

class _PackageInfoOptionsBuilder {
  PackageInfoOptions _options = const PackageInfoOptions();

  void setEnableLogging(bool enableLogging) {
    _options = PackageInfoOptions(
      enableLogging: enableLogging,
      logBuildInfo: _options.logBuildInfo,
    );
  }

  void setLogBuildInfo(bool logBuildInfo) {
    _options = PackageInfoOptions(
      enableLogging: _options.enableLogging,
      logBuildInfo: logBuildInfo,
    );
  }
}

/// Background service that loads PackageInfo and makes it available via DI.
base class PackageInfoBackgroundService extends BackgroundService {
  PackageInfoBackgroundService(
    this._packageInfo,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('PackageInfoService');

  final ValueNotifier<PackageInfo?> _packageInfo;
  final PackageInfoOptions _options;
  final Logger _logger;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    WidgetsFlutterBinding.ensureInitialized();

    _logger.logDebug('PackageInfoService is starting.');

    try {
      final info = await PackageInfo.fromPlatform();
      _packageInfo.value = info;

      if (_options.enableLogging) {
        _logger.log<PackageInfo>(
          logLevel: LogLevel.debug,
          eventId: const EventId(1, 'PackageInfoLoaded'),
          state: info,
          formatter: (state, _) =>
              'PackageInfo loaded: ${state.appName} v${state.version}',
        );

        if (_options.logBuildInfo) {
          _logger.log<PackageInfo>(
            logLevel: LogLevel.debug,
            eventId: const EventId(2, 'PackageInfoDetails'),
            state: info,
            formatter: (state, _) =>
                'Package details - Name: ${state.packageName}, '
                'Build: ${state.buildNumber}, '
                'Signature: ${state.buildSignature}',
          );
        }
      }
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(3, 'PackageInfoLoadFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to load PackageInfo: $state',
      );
    }

    return Future.value();
  }
}
