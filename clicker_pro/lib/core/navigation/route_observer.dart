// lib/core/navigation/route_observer.dart
//
// Tracks the current top route name so the web navigation shell can highlight
// the active sidebar item and decide whether to show chrome. A single shared
// ValueNotifier is updated by the NavigatorObserver and listened to inside
// WebShell. This is web-presentation only and has no effect on mobile logic.

import 'package:flutter/widgets.dart';

/// The path of the route currently on top of the navigator (e.g. '/dashboard').
/// Defaults to the dashboard so the first frame highlights something sensible.
final ValueNotifier<String> currentRouteName = ValueNotifier<String>('/');

/// Global navigator key so widgets mounted in the MaterialApp `builder` (above
/// the Navigator) — like the web sidebar — can still drive navigation.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

/// Observer that keeps [currentRouteName] in sync with the navigation stack.
class AppRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      currentRouteName.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }
}
