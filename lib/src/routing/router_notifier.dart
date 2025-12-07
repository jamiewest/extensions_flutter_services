import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';

class LoggingNavigatorObserver extends NavigatorObserver {
  final Logger _logger;

  LoggingNavigatorObserver(LoggerFactory loggerFactory)
    : _logger = loggerFactory.createLogger('Navigation');

  @override
  void didPush(Route route, Route? previousRoute) {
    final message = _buildMessage('PUSH', route, previousRoute);
    _logger.logDebug(message);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    final message = _buildMessage('POP', route, previousRoute);
    _logger.logDebug(message);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    final newRouteStr = _formatRoute(newRoute);
    final oldRouteStr = _formatRoute(oldRoute);
    _logger.logDebug('REPLACE: $oldRouteStr → $newRouteStr');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    final message = _buildMessage('REMOVE', route, previousRoute);
    _logger.logDebug(message);
  }

  String _buildMessage(String action, Route route, Route? previousRoute) {
    final currentRoute = _formatRoute(route);
    if (previousRoute != null) {
      final prevRoute = _formatRoute(previousRoute);
      return '$action: $prevRoute → $currentRoute';
    }
    return '$action: $currentRoute';
  }

  String _formatRoute(Route? route) {
    if (route == null) return 'null';

    final buffer = StringBuffer();

    // Extract route path/name
    final name = route.settings.name;
    final args = route.settings.arguments;

    if (name != null && name.isNotEmpty) {
      buffer.write(name);
    } else if (args != null) {
      // Try to extract path from GoRouterState arguments
      final argsStr = args.toString();

      // Debug: log the full arguments to understand the structure
      _logger.logDebug('Route args: $argsStr');

      // Try multiple patterns to extract the URI/path
      String? extractedPath;

      // Pattern 1: Look for uri: Uri(...)
      var match = RegExp(r'uri:\s*Uri\(([^)]+)\)').firstMatch(argsStr);
      if (match != null) {
        extractedPath = match.group(1)?.trim();
      }

      // Pattern 2: Look for matchedLocation or path
      if (extractedPath == null) {
        match = RegExp(r'matchedLocation:\s*([^,\)]+)').firstMatch(argsStr);
        extractedPath = match?.group(1)?.trim();
      }

      // Pattern 3: Look for path parameter
      if (extractedPath == null) {
        match = RegExp(r'path:\s*([^,\)]+)').firstMatch(argsStr);
        extractedPath = match?.group(1)?.trim();
      }

      buffer.write(extractedPath ?? '/');
    } else {
      buffer.write('/');
    }

    // Add route type for debugging
    final type = route.runtimeType.toString();
    if (type != 'Route' && type.isNotEmpty) {
      // Simplify common route types
      final simplifiedType = type
          .replaceAll('PageRoute', '')
          .replaceAll('Route', '')
          .replaceAll('<dynamic>', '');
      if (simplifiedType.isNotEmpty) {
        buffer.write(' [$simplifiedType]');
      }
    }

    return buffer.toString();
  }
}
