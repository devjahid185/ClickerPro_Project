// TEMPORARY DEV PROBE — boots the web shell straight onto a routed screen
// (from the URL path, default /dashboard) with NO session and NO splash, so
// web screens can be smoke-tested in a real browser without login. Never
// shipped: only reachable via `flutter run -t lib/main_webprobe.dart`.
//
// Usage:
//   flutter run -d web-server -t lib/main_webprobe.dart --web-port 8123
//   open http://localhost:8123/dashboard (or /calendar, /bookings, …)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/navigation/route_observer.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/web_nav_shell.dart';
import 'shared/widgets/web_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Seed the shell's route notifier BEFORE the first build (mutating it
  // inside onGenerateInitialRoutes fires a listener mid-build).
  final path = Uri.base.path;
  currentRouteName.value =
      (path.isEmpty || path == '/') ? RouteNames.dashboard : path;
  runApp(const ProviderScope(child: _ProbeApp()));
}

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graphy7 probe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.web().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [AppRouteObserver()],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => WebShell(
        child: ValueListenableBuilder<String>(
          valueListenable: currentRouteName,
          builder: (context, route, _) => WebNavShell(
            currentRoute: route,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      onGenerateInitialRoutes: (initialRoute) {
        final route = (initialRoute.isEmpty || initialRoute == '/')
            ? RouteNames.dashboard
            : initialRoute;
        return [AppRouter.onGenerateRoute(RouteSettings(name: route))];
      },
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
