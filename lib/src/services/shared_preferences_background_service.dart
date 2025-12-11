import 'dart:async';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Options for configuring the SharedPreferences service.
class SharedPreferencesOptions {
  const SharedPreferencesOptions({this.prefix = '', this.allowList});

  /// Optional prefix for all keys stored in SharedPreferences.
  final String prefix;

  /// Optional list of allowed keys. If null, all keys are allowed.
  final List<String>? allowList;
}

extension SharedPreferencesServiceExtension on FlutterBuilder {
  ServiceCollection addSharedPreferences([
    void Function(SharedPreferencesOptions)? configure,
  ]) {
    final options = SharedPreferencesOptions();
    if (configure != null) {
      // Since SharedPreferencesOptions is immutable, we need a builder pattern
      final builder = _SharedPreferencesOptionsBuilder();
      configure(builder._options);
      return _addSharedPreferencesWithOptions(builder._options, services);
    }
    return _addSharedPreferencesWithOptions(options, services);
  }

  ServiceCollection _addSharedPreferencesWithOptions(
    SharedPreferencesOptions options,
    ServiceCollection services,
  ) {
    return services
        .addSingleton<SharedPreferencesOptions>((_) => options)
        .addSingleton<SharedPreferencesAsync>((_) => SharedPreferencesAsync())
        .addHostedService<SharedPreferencesBackgroundService>(
          (services) => SharedPreferencesBackgroundService(
            services.getRequiredService<SharedPreferencesAsync>(),
            services.getRequiredService<SharedPreferencesOptions>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

class _SharedPreferencesOptionsBuilder {
  SharedPreferencesOptions _options = const SharedPreferencesOptions();

  void setPrefix(String prefix) {
    _options = SharedPreferencesOptions(
      prefix: prefix,
      allowList: _options.allowList,
    );
  }

  void setAllowList(List<String> allowList) {
    _options = SharedPreferencesOptions(
      prefix: _options.prefix,
      allowList: allowList,
    );
  }
}

/// Background service that initializes SharedPreferences and makes it available via DI.
base class SharedPreferencesBackgroundService extends BackgroundService {
  SharedPreferencesBackgroundService(
    this._sharedPreferences,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('SharedPreferencesService');

  final SharedPreferencesAsync _sharedPreferences;
  final SharedPreferencesOptions _options;
  final Logger _logger;

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    WidgetsFlutterBinding.ensureInitialized();

    _logger.logDebug('SharedPreferencesService is starting.');

    try {
      // Verify SharedPreferences is accessible
      final keys = await _sharedPreferences.getKeys();

      _logger.log<int>(
        logLevel: LogLevel.debug,
        eventId: const EventId(1, 'SharedPreferencesInitialized'),
        state: keys.length,
        formatter: (state, _) =>
            'SharedPreferences initialized with $state keys'
            '${_options.prefix.isNotEmpty ? ' (prefix: ${_options.prefix})' : ''}',
      );

      if (_options.allowList != null) {
        _logger.log<int>(
          logLevel: LogLevel.debug,
          eventId: const EventId(2, 'SharedPreferencesAllowListConfigured'),
          state: _options.allowList!.length,
          formatter: (state, _) =>
              'SharedPreferences allow list configured with $state keys',
        );
      }
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(3, 'SharedPreferencesInitializationFailed'),
        state: error,
        error: error,
        formatter: (state, err) =>
            'Failed to initialize SharedPreferences: $state',
      );
    }

    return Future.value();
  }
}
