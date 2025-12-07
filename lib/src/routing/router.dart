import 'dart:convert';

import 'package:extensions_flutter/extensions_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'router_notifier.dart';

extension GoRouterExtensions on FlutterBuilder {
  ServiceCollection addGoRouter({
    OnEnter? onEnter,
    Codec<Object?, Object?>? extraCodec,
    GoExceptionHandler? onException,
    GoRouterPageBuilder? errorPageBuilder,
    GoRouterWidgetBuilder? errorBuilder,
    GoRouterRedirect? redirect,
    int redirectLimit = 5,
    Listenable? refreshListenable,
    bool routerNeglect = false,
    String? initialLocation,
    bool overridePlatformDefaultLocation = false,
    Object? initialExtra,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = false,
    GlobalKey<NavigatorState>? navigatorKey,
    String? restorationScopeId,
    bool requestFocus = true,
    List<RouteBase> routes = const [],
  }) {
    services.addSingleton<NavigatorObserver>(
      (services) => LoggingNavigatorObserver(
        services.getRequiredService<LoggerFactory>(),
      ),
    );

    return services.addSingleton<GoRouter>(
      (services) => GoRouter(
        onEnter: onEnter,
        extraCodec: extraCodec,
        onException: onException,
        errorPageBuilder: errorPageBuilder,
        errorBuilder: errorBuilder,
        redirect: redirect,
        redirectLimit: redirectLimit,
        refreshListenable: refreshListenable,
        routerNeglect: routerNeglect,
        initialLocation: initialLocation ?? '/',
        overridePlatformDefaultLocation: overridePlatformDefaultLocation,
        initialExtra: initialExtra,
        routes: routes,
        observers:
            observers ?? [services.getRequiredService<NavigatorObserver>()],
        debugLogDiagnostics: debugLogDiagnostics,
        navigatorKey: navigatorKey,
        restorationScopeId: restorationScopeId,
        requestFocus: requestFocus,
      ),
    );
  }
}
