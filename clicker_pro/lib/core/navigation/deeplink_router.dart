// lib/core/navigation/deeplink_router.dart
//
// Translates backend-emitted deeplink strings into in-app
// `(routeName, arguments)` tuples that can be fed straight into
// `Navigator.pushNamed(routeName, arguments: ...)`।
//
// Backend's notification + broadcast records carry a `deeplink` field
// shaped like:
//   /bookings/<id>           → bookingDetail
//   /booking/<id>            → bookingDetail (legacy alias)
//   /re-edit-requests        → reEditRequests
//   /chat                    → chat
//   /reports                 → reports
//   /finance, /expenses      → finance
//   /gear, /rent, /team      → matching screens
//   /notifications           → notifications inbox
//   /dashboard, /            → dashboard
//
// Anything we don't recognise falls back to the dashboard so a stale
// link from an older backend release doesn't blank-screen the user।
//
// Pure Dart — no Flutter, Riverpod, or platform imports — so it can
// be exhaustively unit-tested without a widget pump।

import 'route_names.dart';

class DeeplinkTarget {
  const DeeplinkTarget(this.routeName, {this.arguments});

  final String routeName;
  final Object? arguments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeeplinkTarget &&
          routeName == other.routeName &&
          arguments == other.arguments);

  @override
  int get hashCode => Object.hash(routeName, arguments);

  @override
  String toString() =>
      'DeeplinkTarget(routeName: $routeName, arguments: $arguments)';
}

class DeeplinkRouter {
  const DeeplinkRouter._();

  /// Resolve a backend-emitted deeplink to an in-app navigation target।
  /// Returns null for empty/null input so callers can simply skip
  /// navigation when no link is present।
  static DeeplinkTarget? resolve(String? deeplink) {
    if (deeplink == null) return null;
    final raw = deeplink.trim();
    if (raw.isEmpty) return null;

    // Strip query / fragment — backend currently doesn't use them, but
    // we tolerate them so a future `?ref=push` doesn't break parsing।
    final cleaned = raw.split('?').first.split('#').first;
    final segments = cleaned
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (segments.isEmpty) {
      return const DeeplinkTarget(RouteNames.dashboard);
    }

    final head = segments.first;
    final rest = segments.skip(1).toList(growable: false);

    switch (head) {
      // /bookings, /bookings/<id>
      case 'bookings':
        if (rest.isEmpty) {
          return const DeeplinkTarget(RouteNames.bookings);
        }
        if (rest.first == 'pending-public') {
          return const DeeplinkTarget(RouteNames.pendingPublicBookings);
        }
        return DeeplinkTarget(RouteNames.bookingDetail, arguments: rest.first);

      // /booking/<id>  (legacy singular alias)
      case 'booking':
        if (rest.isEmpty) {
          return const DeeplinkTarget(RouteNames.bookings);
        }
        if (rest.first == 'new') {
          return const DeeplinkTarget(RouteNames.bookingNew);
        }
        if (rest.first == 'edit' && rest.length >= 2) {
          return DeeplinkTarget(RouteNames.bookingEdit, arguments: rest[1]);
        }
        return DeeplinkTarget(RouteNames.bookingDetail, arguments: rest.first);

      case 'calendar':
        return const DeeplinkTarget(RouteNames.calendar);

      case 're-edit-requests':
        return const DeeplinkTarget(RouteNames.reEditRequests);

      case 'public':
        // /public/booking/<token>
        if (rest.length >= 2 && rest.first == 'booking') {
          return DeeplinkTarget(RouteNames.publicBooking, arguments: rest[1]);
        }
        return const DeeplinkTarget(RouteNames.dashboard);

      case 'chat':
        return const DeeplinkTarget(RouteNames.chat);

      case 'reports':
        return const DeeplinkTarget(RouteNames.reports);

      // Both /finance and /expenses route to the same screen — backend
      // hasn't fully decided which name to standardise on।
      case 'finance':
      case 'expenses':
        return const DeeplinkTarget(RouteNames.finance);

      case 'gear':
        return const DeeplinkTarget(RouteNames.gear);
      case 'rent':
        return const DeeplinkTarget(RouteNames.rent);
      case 'team':
        return const DeeplinkTarget(RouteNames.team);

      case 'notifications':
        return const DeeplinkTarget(RouteNames.notifications);

      case 'profile':
        return const DeeplinkTarget(RouteNames.profile);
      case 'settings':
        return const DeeplinkTarget(RouteNames.settings);
      case 'help':
        return const DeeplinkTarget(RouteNames.help);

      case 'privacy':
        return const DeeplinkTarget(RouteNames.privacy);
      case 'terms':
        return const DeeplinkTarget(RouteNames.terms);

      case 'dashboard':
      case 'home':
        return const DeeplinkTarget(RouteNames.dashboard);

      // Unknown head segment — fall back to dashboard so a stale link
      // from an older backend release doesn't blank-screen the user।
      default:
        return const DeeplinkTarget(RouteNames.dashboard);
    }
  }
}
