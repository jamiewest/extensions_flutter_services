import 'package:battery_plus/battery_plus.dart';
import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatteryBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addBattery registers required services', () {
      builder.addBattery();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<BatteryOptions>(),
        isNotNull,
      );
      expect(
        provider.getService<ValueNotifier<BatteryInfoData?>>(),
        isNotNull,
      );
    });

    test('addBattery with default options uses defaults', () {
      builder.addBattery();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<BatteryOptions>();
      expect(options.enableLogging, isTrue);
      expect(options.logStateChanges, isTrue);
      expect(options.logLevelChanges, isFalse);
      expect(options.pollInterval, isNull);
    });

    test('ValueNotifier is initialized with null', () {
      builder.addBattery();
      provider = builder.services.buildServiceProvider();

      final notifier =
          provider.getRequiredService<ValueNotifier<BatteryInfoData?>>();
      expect(notifier.value, isNull);
    });

    test('BatteryInfoData toString returns formatted string', () {
      const data = BatteryInfoData(
        level: 85,
        state: BatteryState.charging,
        isInBatterySaveMode: false,
      );

      expect(
        data.toString(),
        'BatteryInfoData(level: 85%, state: BatteryState.charging, saveMode: false)',
      );
    });

    test('BatteryInfoData properties are accessible', () {
      const data = BatteryInfoData(
        level: 50,
        state: BatteryState.discharging,
        isInBatterySaveMode: true,
      );

      expect(data.level, 50);
      expect(data.state, BatteryState.discharging);
      expect(data.isInBatterySaveMode, isTrue);
    });

    test('multiple calls to addBattery override previous registration', () {
      builder.addBattery();
      builder.addBattery();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<BatteryOptions>();
      expect(options, isNotNull);
    });
  });

  group('BatteryOptions', () {
    test('default constructor sets expected defaults', () {
      const options = BatteryOptions();

      expect(options.enableLogging, isTrue);
      expect(options.logStateChanges, isTrue);
      expect(options.logLevelChanges, isFalse);
      expect(options.pollInterval, isNull);
    });

    test('can create with custom values', () {
      const options = BatteryOptions(
        enableLogging: false,
        logStateChanges: false,
        logLevelChanges: true,
        pollInterval: Duration(seconds: 30),
      );

      expect(options.enableLogging, isFalse);
      expect(options.logStateChanges, isFalse);
      expect(options.logLevelChanges, isTrue);
      expect(options.pollInterval, const Duration(seconds: 30));
    });
  });
}
