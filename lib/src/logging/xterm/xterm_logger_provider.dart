import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:xterm/xterm.dart';

import 'xterm_logger.dart';

class XtermLoggerProvider extends LoggerProvider {
  XtermLoggerProvider(this.terminal);
  final Terminal terminal;
  @override
  Logger createLogger(String categoryName) =>
      XtermLogger(terminal, categoryName);

  @override
  void dispose() {
    //terminal.setCursorVisibleMode(true);
  }
}
