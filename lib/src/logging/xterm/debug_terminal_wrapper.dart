import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/material.dart';

import 'debug_terminal_overlay.dart';
import 'xterm_logger_factory_extensions.dart';

/// Wraps a widget with a debug terminal overlay if in development mode.
class DebugTerminalWrapper extends StatelessWidget {
  const DebugTerminalWrapper({
    super.key,
    required this.services,
    required this.child,
  });

  final ServiceProvider services;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hostEnvironment = services.getRequiredService<HostEnvironment>();

    // Only show debug terminal in development
    if (hostEnvironment.isDevelopment()) {
      final terminalWrapper = services.getService<TerminalWrapper>();

      if (terminalWrapper != null) {
        // Wrap with WidgetsApp.debugAllowBannerOverride to ensure proper initialization
        return DebugTerminalOverlay(
          terminal: terminalWrapper.terminal,
          child: child,
        );
      } else {
        // TerminalWrapper not found - just return child
        debugPrint('DebugTerminalWrapper: TerminalWrapper not found in services');
      }
    }

    return child;
  }
}
