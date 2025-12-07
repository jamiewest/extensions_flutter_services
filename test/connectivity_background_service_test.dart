import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:extensions_flutter_services/extensions_flutter_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityBackgroundService', () {
    late FlutterBuilder builder;
    late ServiceProvider provider;

    setUp(() {
      final services = ServiceCollection();
      services.addLogging((loggingBuilder) => loggingBuilder.addDebug());
      builder = FlutterBuilder(services);
    });

    test('addConnectivityService registers required services', () {
      builder.addConnectivityService();
      provider = builder.services.buildServiceProvider();

      expect(
        provider.getService<Connectivity>(),
        isNotNull,
      );
      expect(
        provider.getService<ValueNotifier<List<ConnectivityResult>>>(),
        isNotNull,
      );
    });

    test('ValueNotifier is initialized with ConnectivityResult.none', () {
      builder.addConnectivityService();
      provider = builder.services.buildServiceProvider();

      final notifier = provider
          .getRequiredService<ValueNotifier<List<ConnectivityResult>>>();
      expect(notifier.value, [ConnectivityResult.none]);
    });

    test('multiple calls to addConnectivityService override previous registration',
        () {
      builder.addConnectivityService();
      builder.addConnectivityService();
      provider = builder.services.buildServiceProvider();

      final connectivity = provider.getRequiredService<Connectivity>();
      expect(connectivity, isNotNull);
    });

    test('Connectivity instance is singleton', () {
      builder.addConnectivityService();
      provider = builder.services.buildServiceProvider();

      final connectivity1 = provider.getRequiredService<Connectivity>();
      final connectivity2 = provider.getRequiredService<Connectivity>();
      expect(identical(connectivity1, connectivity2), isTrue);
    });

    test('ValueNotifier instance is singleton', () {
      builder.addConnectivityService();
      provider = builder.services.buildServiceProvider();

      final notifier1 = provider
          .getRequiredService<ValueNotifier<List<ConnectivityResult>>>();
      final notifier2 = provider
          .getRequiredService<ValueNotifier<List<ConnectivityResult>>>();
      expect(identical(notifier1, notifier2), isTrue);
    });
  });
}
