import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkInfoBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addNetworkInfo registers required services', () {
      builder.addNetworkInfo();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<NetworkInfoOptions>(),
        isNotNull,
      );
      expect(
        provider.getService<ValueNotifier<NetworkInfoData?>>(),
        isNotNull,
      );
    });

    test('addNetworkInfo with default options uses defaults', () {
      builder.addNetworkInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<NetworkInfoOptions>();
      expect(options.enableLogging, isTrue);
      expect(options.logDetailedInfo, isFalse);
      expect(options.refreshInterval, isNull);
    });

    test('ValueNotifier is initialized with null', () {
      builder.addNetworkInfo();
      provider = builder.services.buildServiceProvider();

      final notifier =
          provider.getRequiredService<ValueNotifier<NetworkInfoData?>>();
      expect(notifier.value, isNull);
    });

    test('multiple calls to addNetworkInfo override previous registration', () {
      builder.addNetworkInfo();
      builder.addNetworkInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<NetworkInfoOptions>();
      expect(options, isNotNull);
    });
  });

  group('NetworkInfoOptions', () {
    test('default constructor sets expected defaults', () {
      const options = NetworkInfoOptions();

      expect(options.enableLogging, isTrue);
      expect(options.logDetailedInfo, isFalse);
      expect(options.refreshInterval, isNull);
    });

    test('can create with custom values', () {
      const options = NetworkInfoOptions(
        enableLogging: false,
        logDetailedInfo: true,
        refreshInterval: Duration(minutes: 5),
      );

      expect(options.enableLogging, isFalse);
      expect(options.logDetailedInfo, isTrue);
      expect(options.refreshInterval, const Duration(minutes: 5));
    });
  });

  group('NetworkInfoData', () {
    test('toString returns formatted string with key info', () {
      const data = NetworkInfoData(
        wifiName: 'MyWiFi',
        wifiIP: '192.168.1.100',
        wifiGatewayIP: '192.168.1.1',
      );

      expect(
        data.toString(),
        'NetworkInfoData(name: MyWiFi, IP: 192.168.1.100, gateway: 192.168.1.1)',
      );
    });

    test('toString handles null values', () {
      const data = NetworkInfoData();

      expect(
        data.toString(),
        'NetworkInfoData(name: null, IP: null, gateway: null)',
      );
    });

    test('all fields are nullable', () {
      const data = NetworkInfoData();

      expect(data.wifiName, isNull);
      expect(data.wifiBSSID, isNull);
      expect(data.wifiIP, isNull);
      expect(data.wifiIPv6, isNull);
      expect(data.wifiGatewayIP, isNull);
      expect(data.wifiSubmask, isNull);
      expect(data.wifiBroadcast, isNull);
    });

    test('can create with all fields populated', () {
      const data = NetworkInfoData(
        wifiName: 'TestNetwork',
        wifiBSSID: '00:11:22:33:44:55',
        wifiIP: '192.168.1.50',
        wifiIPv6: 'fe80::1',
        wifiGatewayIP: '192.168.1.1',
        wifiSubmask: '255.255.255.0',
        wifiBroadcast: '192.168.1.255',
      );

      expect(data.wifiName, 'TestNetwork');
      expect(data.wifiBSSID, '00:11:22:33:44:55');
      expect(data.wifiIP, '192.168.1.50');
      expect(data.wifiIPv6, 'fe80::1');
      expect(data.wifiGatewayIP, '192.168.1.1');
      expect(data.wifiSubmask, '255.255.255.0');
      expect(data.wifiBroadcast, '192.168.1.255');
    });
  });
}
