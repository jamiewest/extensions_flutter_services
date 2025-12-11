import 'package:extensions_flutter/extensions_flutter.dart';

import 'package:xterm/xterm.dart';

import 'debug_terminal_wrapper.dart';
import 'xterm_logger_provider.dart';

/// Extension methods for the [LoggerFactory] class.
///
/// Adds Xterm-based logging capabilities.
extension XtermLoggerFactoryExtensions on LoggingBuilder {
  LoggingBuilder addXtermLogging() {
    services.addSingletonInstance<TerminalWrapper>(TerminalWrapper(Terminal()));
    services.tryAddIterable(
      ServiceDescriptor.singleton<LoggerProvider>(
        (sp) => XtermLoggerProvider(
          sp.getRequiredService<TerminalWrapper>().terminal,
        ),
      ),
    );
    services.addSingleton<RegisteredWidgetFactory>(
      (_) =>
          (sp, child) => DebugTerminalWrapper(services: sp, child: child),
    );
    return this;
  }
}

class TerminalWrapper {
  TerminalWrapper(this.terminal);
  final Terminal terminal;
}
