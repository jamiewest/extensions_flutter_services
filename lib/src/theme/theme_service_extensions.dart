import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/material.dart';

import 'platform_brightness_service.dart';
import 'theme_notifier.dart';
import 'theme_service.dart';

extension ThemeServiceExtensions on FlutterBuilder {
  FlutterBuilder addThemeService({ThemeMode? mode}) {
    // Register theme services
    services.addSingleton<ThemeService>((services) => ThemeService());
    services.addSingleton<ThemeNotifier>(
      (services) => ThemeNotifier(
        services.getRequiredService<ThemeService>(),
        services.getRequiredService<PlatformBrightnessService>(),
        services.getRequiredService<LoggerFactory>(),
      ),
    );
    return this;
  }
}
