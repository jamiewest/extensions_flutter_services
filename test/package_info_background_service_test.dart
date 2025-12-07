import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('PackageInfoBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addPackageInfo registers required services', () {
      builder.addPackageInfo();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<PackageInfoOptions>(),
        isNotNull,
      );
      expect(
        provider.getService<ValueNotifier<PackageInfo?>>(),
        isNotNull,
      );
    });

    test('addPackageInfo with default options uses defaults', () {
      builder.addPackageInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<PackageInfoOptions>();
      expect(options.enableLogging, isTrue);
      expect(options.logBuildInfo, isFalse);
    });

    test('ValueNotifier is initialized with null', () {
      builder.addPackageInfo();
      provider = builder.services.buildServiceProvider();

      final notifier =
          provider.getRequiredService<ValueNotifier<PackageInfo?>>();
      expect(notifier.value, isNull);
    });

    test('multiple calls to addPackageInfo override previous registration', () {
      builder.addPackageInfo();
      builder.addPackageInfo();
      provider = builder.services.buildServiceProvider();

      final options = provider.getRequiredService<PackageInfoOptions>();
      expect(options, isNotNull);
    });
  });

  group('PackageInfoOptions', () {
    test('default constructor sets expected defaults', () {
      const options = PackageInfoOptions();

      expect(options.enableLogging, isTrue);
      expect(options.logBuildInfo, isFalse);
    });

    test('can create with custom values', () {
      const options = PackageInfoOptions(
        enableLogging: false,
        logBuildInfo: true,
      );

      expect(options.enableLogging, isFalse);
      expect(options.logBuildInfo, isTrue);
    });
  });
}
