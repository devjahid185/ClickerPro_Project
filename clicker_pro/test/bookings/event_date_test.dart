// Regression tests for the event-date timezone bug: a date-only event value
// (the shoot day) used to flow through a datetime formatter after a UTC→local
// shift, surfacing a spurious clock time (e.g. "06:00" in Bangladesh) and, in
// negative-offset zones, shifting the day. See serverEventDate + dateOnly.

import 'package:clicker_pro/core/format/booking_format.dart';
import 'package:clicker_pro/features/bookings/data/server_wire.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
    await initializeDateFormatting('en');
  });
  group('serverEventDate', () {
    test('collapses a UTC-midnight instant to the same calendar day', () {
      // Laravel `date` cast serializes as an ISO instant at UTC midnight.
      final d = serverEventDate('2026-07-08T00:00:00.000000Z')!;
      expect(d.year, 2026);
      expect(d.month, 7);
      expect(d.day, 8);
      // No spurious time component, and the value is a plain local DateTime.
      expect(d.hour, 0);
      expect(d.minute, 0);
      expect(d.isUtc, isFalse);
    });

    test('handles a naive date-only string', () {
      final d = serverEventDate('2026-07-08')!;
      expect(d.year, 2026);
      expect(d.month, 7);
      expect(d.day, 8);
      expect(d.hour, 0);
    });

    test('returns null for null/garbage', () {
      expect(serverEventDate(null), isNull);
      expect(serverEventDate('not-a-date'), isNull);
    });
  });

  group('BookingFormat.dateOnly', () {
    test('renders the calendar day with no clock time', () {
      final out = BookingFormat.dateOnly(DateTime(2026, 7, 8), lang: 'en');
      expect(out, contains('2026'));
      expect(out, contains('8'));
      // No "HH:mm" time component leaks in.
      expect(RegExp(r'\d{1,2}:\d{2}').hasMatch(out), isFalse);
    });

    test('bn emits only Bengali digits', () {
      final out = BookingFormat.dateOnly(DateTime(2026, 7, 8), lang: 'bn');
      expect(RegExp(r'[0-9]').hasMatch(out), isFalse);
    });
  });
}
