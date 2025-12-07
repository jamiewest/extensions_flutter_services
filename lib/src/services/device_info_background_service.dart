import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/foundation.dart';

/// Device information data class that holds platform-specific info.
class DeviceInfoData {
  const DeviceInfoData({
    this.androidInfo,
    this.iosInfo,
    this.webBrowserInfo,
    this.macOsInfo,
    this.linuxInfo,
    this.windowsInfo,
  });

  final AndroidDeviceInfo? androidInfo;
  final IosDeviceInfo? iosInfo;
  final WebBrowserInfo? webBrowserInfo;
  final MacOsDeviceInfo? macOsInfo;
  final LinuxDeviceInfo? linuxInfo;
  final WindowsDeviceInfo? windowsInfo;

  /// Get a generic device identifier string across platforms
  String get deviceIdentifier {
    if (androidInfo != null) {
      return '${androidInfo!.manufacturer} ${androidInfo!.model}';
    } else if (iosInfo != null) {
      return '${iosInfo!.name} (${iosInfo!.model})';
    } else if (webBrowserInfo != null) {
      return '${webBrowserInfo!.browserName} on ${webBrowserInfo!.platform}';
    } else if (macOsInfo != null) {
      return 'macOS ${macOsInfo!.computerName}';
    } else if (linuxInfo != null) {
      return 'Linux ${linuxInfo!.prettyName}';
    } else if (windowsInfo != null) {
      return 'Windows ${windowsInfo!.productName}';
    }
    return 'Unknown Device';
  }

  /// Get the OS version string across platforms
  String get osVersion {
    if (androidInfo != null) {
      return 'Android ${androidInfo!.version.release}';
    } else if (iosInfo != null) {
      return 'iOS ${iosInfo!.systemVersion}';
    } else if (webBrowserInfo != null) {
      return webBrowserInfo!.userAgent ?? 'Unknown';
    } else if (macOsInfo != null) {
      return 'macOS ${macOsInfo!.osRelease}';
    } else if (linuxInfo != null) {
      return 'Linux ${linuxInfo!.version}';
    } else if (windowsInfo != null) {
      return 'Windows ${windowsInfo!.majorVersion}.${windowsInfo!.minorVersion}';
    }
    return 'Unknown OS';
  }

  @override
  String toString() {
    return 'DeviceInfoData(device: $deviceIdentifier, os: $osVersion)';
  }
}

/// Options for configuring the DeviceInfo service.
class DeviceInfoOptions {
  const DeviceInfoOptions({
    this.enableLogging = true,
    this.logDetailedInfo = false,
  });

  /// Whether to enable logging of device info initialization.
  final bool enableLogging;

  /// Whether to log detailed platform-specific information.
  final bool logDetailedInfo;
}

extension DeviceInfoServiceExtension on FlutterBuilder {
  ServiceCollection addDeviceInfo([
    void Function(DeviceInfoOptions)? configure,
  ]) {
    final options = DeviceInfoOptions();
    if (configure != null) {
      // Since DeviceInfoOptions is immutable, we need a builder pattern
      final builder = _DeviceInfoOptionsBuilder();
      configure(builder._options);
      return _addDeviceInfoWithOptions(builder._options);
    }
    return _addDeviceInfoWithOptions(options);
  }

  ServiceCollection _addDeviceInfoWithOptions(DeviceInfoOptions options) {
    return services
        .addSingleton<DeviceInfoOptions>((_) => options)
        .addSingleton<ValueNotifier<DeviceInfoData?>>(
          (_) => ValueNotifier<DeviceInfoData?>(null),
        )
        .addHostedService<DeviceInfoBackgroundService>(
          (services) => DeviceInfoBackgroundService(
            services.getRequiredService<ValueNotifier<DeviceInfoData?>>(),
            services.getRequiredService<DeviceInfoOptions>(),
            services.getRequiredService<LoggerFactory>(),
          ),
        );
  }
}

class _DeviceInfoOptionsBuilder {
  DeviceInfoOptions _options = const DeviceInfoOptions();

  void setEnableLogging(bool enableLogging) {
    _options = DeviceInfoOptions(
      enableLogging: enableLogging,
      logDetailedInfo: _options.logDetailedInfo,
    );
  }

  void setLogDetailedInfo(bool logDetailedInfo) {
    _options = DeviceInfoOptions(
      enableLogging: _options.enableLogging,
      logDetailedInfo: logDetailedInfo,
    );
  }
}

/// Background service that loads DeviceInfo and makes it available via DI.
base class DeviceInfoBackgroundService extends BackgroundService {
  DeviceInfoBackgroundService(
    this._deviceInfoNotifier,
    this._options,
    LoggerFactory loggerFactory,
  ) : _logger = loggerFactory.createLogger('DeviceInfoBackgroundService');

  final ValueNotifier<DeviceInfoData?> _deviceInfoNotifier;
  final DeviceInfoOptions _options;
  final Logger _logger;
  final _deviceInfo = DeviceInfoPlugin();

  @override
  Future<void> execute(CancellationToken stoppingToken) async {
    try {
      DeviceInfoData info;

      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        info = DeviceInfoData(webBrowserInfo: webInfo);

        if (_options.logDetailedInfo) {
          _logWebDetails(webInfo);
        }
      } else if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info = DeviceInfoData(androidInfo: androidInfo);

        if (_options.logDetailedInfo) {
          _logAndroidDetails(androidInfo);
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info = DeviceInfoData(iosInfo: iosInfo);

        if (_options.logDetailedInfo) {
          _logIosDetails(iosInfo);
        }
      } else if (!kIsWeb && Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info = DeviceInfoData(macOsInfo: macInfo);

        if (_options.logDetailedInfo) {
          _logMacOsDetails(macInfo);
        }
      } else if (!kIsWeb && Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info = DeviceInfoData(linuxInfo: linuxInfo);

        if (_options.logDetailedInfo) {
          _logLinuxDetails(linuxInfo);
        }
      } else if (!kIsWeb && Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info = DeviceInfoData(windowsInfo: windowsInfo);

        if (_options.logDetailedInfo) {
          _logWindowsDetails(windowsInfo);
        }
      } else {
        _logger.log<String>(
          logLevel: LogLevel.warning,
          eventId: const EventId(9, 'UnsupportedPlatform'),
          state: 'Unsupported platform',
          formatter: (state, _) => 'Device info not supported on this platform',
        );
        return Future.value();
      }

      _deviceInfoNotifier.value = info;

      if (_options.enableLogging) {
        _logger.log<DeviceInfoData>(
          logLevel: LogLevel.information,
          eventId: const EventId(1, 'DeviceInfoLoaded'),
          state: info,
          formatter: (state, _) =>
              'Device info loaded: ${state.deviceIdentifier} running ${state.osVersion}',
        );
      }
    } on Exception catch (error) {
      _logger.log<Exception>(
        logLevel: LogLevel.error,
        eventId: const EventId(2, 'DeviceInfoLoadFailed'),
        state: error,
        error: error,
        formatter: (state, err) => 'Failed to load device info: $state',
      );
    }

    return Future.value();
  }

  void _logAndroidDetails(AndroidDeviceInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(3, 'AndroidDeviceDetails'),
      state: 'Android device details',
      formatter: (state, error) =>
          'Android - Manufacturer: ${info.manufacturer}, '
          'Model: ${info.model}, '
          'Brand: ${info.brand}, '
          'SDK: ${info.version.sdkInt}, '
          'Release: ${info.version.release}, '
          'Hardware: ${info.hardware}, '
          'Product: ${info.product}',
    );
  }

  void _logIosDetails(IosDeviceInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(4, 'IosDeviceDetails'),
      state: 'iOS device details',
      formatter: (state, error) =>
          'iOS - Name: ${info.name}, '
          'Model: ${info.model}, '
          'System: ${info.systemName} ${info.systemVersion}, '
          'Machine: ${info.utsname.machine}, '
          'Localized Model: ${info.localizedModel}',
    );
  }

  void _logWebDetails(WebBrowserInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(5, 'WebBrowserDetails'),
      state: 'Web browser details',
      formatter: (state, error) =>
          'Web - Browser: ${info.browserName}, '
          'Platform: ${info.platform}, '
          'User Agent: ${info.userAgent}',
    );
  }

  void _logMacOsDetails(MacOsDeviceInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(6, 'MacOsDeviceDetails'),
      state: 'macOS device details',
      formatter: (state, error) =>
          'macOS - Computer: ${info.computerName}, '
          'Model: ${info.model}, '
          'OS Release: ${info.osRelease}, '
          'Kernel Version: ${info.kernelVersion}, '
          'Arch: ${info.arch}',
    );
  }

  void _logLinuxDetails(LinuxDeviceInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(7, 'LinuxDeviceDetails'),
      state: 'Linux device details',
      formatter: (state, error) =>
          'Linux - Name: ${info.name}, '
          'Pretty Name: ${info.prettyName}, '
          'Version: ${info.version}, '
          'ID: ${info.id}, '
          'Variant: ${info.variant}',
    );
  }

  void _logWindowsDetails(WindowsDeviceInfo info) {
    _logger.log<String>(
      logLevel: LogLevel.debug,
      eventId: const EventId(8, 'WindowsDeviceDetails'),
      state: 'Windows device details',
      formatter: (state, error) =>
          'Windows - Product: ${info.productName}, '
          'Version: ${info.majorVersion}.${info.minorVersion}.${info.buildNumber}, '
          'Edition: ${info.displayVersion}, '
          'Computer: ${info.computerName}',
    );
  }
}
