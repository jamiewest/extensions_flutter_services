import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:xterm/xterm.dart';

class XtermLogger extends Logger {
  XtermLogger(this.terminal, this.name) {
    terminal.setCursorVisibleMode(false);
  }
  final Terminal terminal;
  final String _logLevelPadding = ': ';
  final String name;

  @override
  Disposable beginScope<TState>(TState state) => NullScope.instance;

  @override
  bool isEnabled(LogLevel logLevel) => logLevel != LogLevel.none;

  @override
  void log<TState>({
    required LogLevel logLevel,
    required EventId eventId,
    required TState state,
    Object? error,
    required LogFormatter<TState> formatter,
  }) {
    final formattedMessage = formatter(state, error);
    if (formattedMessage.isEmpty) {
      return;
    }
    final sb = StringBuffer();
    final logLevelString = _getLogLevelString(logLevel);

    sb.write(logLevelString);
    sb.write(_logLevelPadding);
    sb.write(name);
    sb.write('[');
    sb.write(eventId.id);
    sb.write(']');
    sb.write(' ');
    sb.write(formattedMessage);
    sb.write('\r\n');

    terminal.write(sb.toString());
    terminal.clearAllTabStops();
  }

  String _getLogLevelString(LogLevel logLevel) {
    return switch (logLevel) {
      LogLevel.trace => 'trce',
      LogLevel.debug => 'dbug',
      LogLevel.information => 'info',
      LogLevel.warning => 'warn',
      LogLevel.error => 'fail',
      LogLevel.critical => 'crit',
      LogLevel.none => '',
    };
  }
}
