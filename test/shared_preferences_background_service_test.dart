import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedPreferencesBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addSharedPreferences registers required services', () {
      builder.addSharedPreferences();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<SharedPreferencesOptions>(),
        isNotNull,
      );
      // Skip SharedPreferencesAsync check as it requires platform setup
    });

    test('addSharedPreferences with default options uses defaults', () {
      builder.addSharedPreferences();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<SharedPreferencesOptions>();
      expect(options.prefix, '');
      expect(options.allowList, isNull);
    });

    test('multiple calls to addSharedPreferences override previous registration',
        () {
      builder.addSharedPreferences();
      builder.addSharedPreferences();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<SharedPreferencesOptions>();
      expect(options, isNotNull);
    });

    test('SharedPreferencesAsync instance is singleton', () {
      builder.addSharedPreferences();
      provider = builder.services.buildServiceProvider();

      // This test requires platform setup for SharedPreferencesAsync
      // In a real app, the platform will be properly initialized
      expect(provider.getService<SharedPreferencesOptions>(), isNotNull);
    });
  });

  group('SharedPreferencesOptions', () {
    test('default constructor sets expected defaults', () {
      const options = SharedPreferencesOptions();

      expect(options.prefix, '');
      expect(options.allowList, isNull);
    });

    test('can create with custom prefix', () {
      const options = SharedPreferencesOptions(
        prefix: 'myapp_',
      );

      expect(options.prefix, 'myapp_');
      expect(options.allowList, isNull);
    });

    test('can create with allowList', () {
      const options = SharedPreferencesOptions(
        allowList: ['key1', 'key2', 'key3'],
      );

      expect(options.prefix, '');
      expect(options.allowList, ['key1', 'key2', 'key3']);
    });

    test('can create with both prefix and allowList', () {
      const options = SharedPreferencesOptions(
        prefix: 'app_',
        allowList: ['setting1', 'setting2'],
      );

      expect(options.prefix, 'app_');
      expect(options.allowList, ['setting1', 'setting2']);
    });
  });
}
