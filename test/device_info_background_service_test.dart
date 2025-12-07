import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceInfoBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addDeviceInfo registers required services', () {
      builder.addDeviceInfo();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<DeviceInfoOptions>(),
        isNotNull,
      );
      expect(
        provider.getService<ValueNotifier<DeviceInfoData?>>(),
        isNotNull,
      );
    });

    test('addDeviceInfo with default options uses defaults', () {
      builder.addDeviceInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<DeviceInfoOptions>();
      expect(options.enableLogging, isTrue);
      expect(options.logDetailedInfo, isFalse);
    });

    test('ValueNotifier is initialized with null', () {
      builder.addDeviceInfo();
      provider = builder.services.buildServiceProvider();

      final notifier =
          provider.getRequiredService<ValueNotifier<DeviceInfoData?>>();
      expect(notifier.value, isNull);
    });

    test('multiple calls to addDeviceInfo override previous registration', () {
      builder.addDeviceInfo();
      builder.addDeviceInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<DeviceInfoOptions>();
      expect(options, isNotNull);
    });
  });

  group('DeviceInfoOptions', () {
    test('default constructor sets expected defaults', () {
      const options = DeviceInfoOptions();

      expect(options.enableLogging, isTrue);
      expect(options.logDetailedInfo, isFalse);
    });

    test('can create with custom values', () {
      const options = DeviceInfoOptions(
        enableLogging: false,
        logDetailedInfo: true,
      );

      expect(options.enableLogging, isFalse);
      expect(options.logDetailedInfo, isTrue);
    });
  });

  group('DeviceInfoData', () {
    test('toString returns formatted string with device identifier', () {
      const data = DeviceInfoData();

      expect(
        data.toString(),
        'DeviceInfoData(device: Unknown Device, os: Unknown OS)',
      );
    });

    test('deviceIdentifier returns Unknown Device when no info available', () {
      const data = DeviceInfoData();

      expect(data.deviceIdentifier, 'Unknown Device');
    });

    test('osVersion returns Unknown OS when no info available', () {
      const data = DeviceInfoData();

      expect(data.osVersion, 'Unknown OS');
    });

    test('all platform info fields are nullable', () {
      const data = DeviceInfoData();

      expect(data.androidInfo, isNull);
      expect(data.iosInfo, isNull);
      expect(data.webBrowserInfo, isNull);
      expect(data.macOsInfo, isNull);
      expect(data.linuxInfo, isNull);
      expect(data.windowsInfo, isNull);
    });
  });
}
