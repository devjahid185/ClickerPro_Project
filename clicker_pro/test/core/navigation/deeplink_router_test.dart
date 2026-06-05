// test/core/navigation/deeplink_router_test.dart
//
// Pure-Dart unit tests for `DeeplinkRouter.resolve`।  No widget pump,
// no async — just predicate-style assertions over the (input → output)
// table to guarantee every backend deeplink shape lands on the right
// in-app route।

import 'package:clicker_pro/core/navigation/deeplink_router.dart';
import 'package:clicker_pro/core/navigation/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeeplinkRouter.resolve — null / empty / unknown', () {
    test('null → null', () {
      expect(DeeplinkRouter.resolve(null), isNull);
    });

    test('empty string → null', () {
      expect(DeeplinkRouter.resolve(''), isNull);
    });

    test('whitespace → null', () {
      expect(DeeplinkRouter.resolve('   '), isNull);
    });

    test('"/" → dashboard', () {
      expect(
        DeeplinkRouter.resolve('/'),
        equals(const DeeplinkTarget(RouteNames.dashboard)),
      );
    });

    test('unknown head → dashboard fallback', () {
      expect(
        DeeplinkRouter.resolve('/some/unknown/path'),
        equals(const DeeplinkTarget(RouteNames.dashboard)),
      );
    });

    test('strips query and fragment', () {
      expect(
        DeeplinkRouter.resolve('/bookings/evt-1?ref=push#x'),
        equals(
          const DeeplinkTarget(RouteNames.bookingDetail, arguments: 'evt-1'),
        ),
      );
    });
  });

  group('Bookings', () {
    test('/bookings → list', () {
      expect(
        DeeplinkRouter.resolve('/bookings'),
        equals(const DeeplinkTarget(RouteNames.bookings)),
      );
    });

    test('/bookings/<id> → detail with id arg', () {
      expect(
        DeeplinkRouter.resolve('/bookings/evt-42'),
        equals(
          const DeeplinkTarget(RouteNames.bookingDetail, arguments: 'evt-42'),
        ),
      );
    });

    test('/bookings/pending-public → pending public bookings', () {
      expect(
        DeeplinkRouter.resolve('/bookings/pending-public'),
        equals(const DeeplinkTarget(RouteNames.pendingPublicBookings)),
      );
    });

    test('/booking/<id> (legacy singular) → detail', () {
      expect(
        DeeplinkRouter.resolve('/booking/evt-99'),
        equals(
          const DeeplinkTarget(RouteNames.bookingDetail, arguments: 'evt-99'),
        ),
      );
    });

    test('/booking/new → bookingNew', () {
      expect(
        DeeplinkRouter.resolve('/booking/new'),
        equals(const DeeplinkTarget(RouteNames.bookingNew)),
      );
    });

    test('/booking/edit/<id> → bookingEdit with id arg', () {
      expect(
        DeeplinkRouter.resolve('/booking/edit/evt-7'),
        equals(
          const DeeplinkTarget(RouteNames.bookingEdit, arguments: 'evt-7'),
        ),
      );
    });

    test('/calendar', () {
      expect(
        DeeplinkRouter.resolve('/calendar'),
        equals(const DeeplinkTarget(RouteNames.calendar)),
      );
    });

    test('/re-edit-requests', () {
      expect(
        DeeplinkRouter.resolve('/re-edit-requests'),
        equals(const DeeplinkTarget(RouteNames.reEditRequests)),
      );
    });
  });

  group('Public booking', () {
    test('/public/booking/<token> → publicBooking with token arg', () {
      expect(
        DeeplinkRouter.resolve('/public/booking/CP-XYZ123'),
        equals(
          const DeeplinkTarget(
            RouteNames.publicBooking,
            arguments: 'CP-XYZ123',
          ),
        ),
      );
    });

    test('/public alone → dashboard fallback', () {
      expect(
        DeeplinkRouter.resolve('/public'),
        equals(const DeeplinkTarget(RouteNames.dashboard)),
      );
    });
  });

  group('Other top-level routes', () {
    final cases = <String, String>{
      '/chat': RouteNames.chat,
      '/reports': RouteNames.reports,
      '/finance': RouteNames.finance,
      '/expenses': RouteNames.finance,
      '/gear': RouteNames.gear,
      '/rent': RouteNames.rent,
      '/team': RouteNames.team,
      '/notifications': RouteNames.notifications,
      '/profile': RouteNames.profile,
      '/settings': RouteNames.settings,
      '/help': RouteNames.help,
      '/privacy': RouteNames.privacy,
      '/terms': RouteNames.terms,
      '/dashboard': RouteNames.dashboard,
      '/home': RouteNames.dashboard,
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(
          DeeplinkRouter.resolve(entry.key),
          equals(DeeplinkTarget(entry.value)),
        );
      });
    }
  });
}
