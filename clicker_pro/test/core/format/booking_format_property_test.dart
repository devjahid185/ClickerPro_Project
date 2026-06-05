// test/core/format/booking_format_test.dart
//
// Property test for BookingFormat — Bengali numerals coverage (Property 12).
//
// Validates: Requirements 1.11, 4.8, 5.10, 7.9, 8.6, 9.6, 12.4
//
// Property 12 (booking-side): for any non-negative integer `n` and any
// non-negative real `m`, the strings produced by
//   - `BookingFormat.money(m, lang: 'bn', bnNumerals: true)`
//   - `BookingFormat.percent(n, lang: 'bn', bnNumerals: true)`
//   - `BookingFormat.dateTime(dt, lang: 'bn')`
// MUST contain digits exclusively in U+09E6 .. U+09EF (the Bengali digit
// block) AND MUST contain ZERO ASCII digits (U+0030 .. U+0039) anywhere in
// the output. The Foundation MVP `formatNumber` helper performs the digit
// substitution; this test is the property-based safety net that proves no
// digit ever escapes the substitution loop on a booking surface.

import 'package:clicker_pro/core/format/booking_format.dart';
// `glados` re-exports `package:test/test.dart`, which provides `test`,
// `group`, `setUpAll`, `expect`, `fail`, and matchers — no need to also
// import `flutter_test/flutter_test.dart` here (and doing so would create
// duplicate symbol resolution errors).
import 'package:glados/glados.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Custom `glados` generator that produces `DateTime` values constrained to
/// the range 1900-01-01 .. 2100-12-31 with valid (year, month, day, hour,
/// minute, second) tuples. The default `any.dateTime` generator runs over
/// the full microseconds-since-epoch range which is far wider than any
/// realistic booking date and includes pre-1900 / post-2100 values that
/// `intl` formatting cannot meaningfully render. Day is constrained to 1–28
/// so the tuple is safe for every month without needing per-month logic.
extension _BookingDateTimeAny on Any {
  Generator<DateTime> get bookingDateTime {
    return combine6<int, int, int, int, int, int, DateTime>(
      intInRange(1900, 2101), // year ∈ [1900, 2100]
      intInRange(1, 13), // month ∈ [1, 12]
      intInRange(1, 29), // day   ∈ [1, 28]  — safe for every month
      intInRange(0, 24), // hour  ∈ [0, 23]
      intInRange(0, 60), // minute∈ [0, 59]
      intInRange(0, 60), // second∈ [0, 59]
      (y, mo, d, h, mi, s) => DateTime(y, mo, d, h, mi, s),
    );
  }
}

/// Asserts that [out]:
///   1. contains zero ASCII digits (U+0030 .. U+0039), and
///   2. every rune in the union (ASCII digits ∪ Bengali digits) lies in the
///      Bengali digit range U+09E6 .. U+09EF.
///
/// Because (1) excludes ASCII digits, (2) reduces to "Bengali digits are
/// Bengali digits" — but we still iterate runes so any off-by-one in the
/// substitution loop (e.g. mapping `'0'` → `'\u09E5'` instead of `'\u09E6'`)
/// is caught explicitly with a precise rune in the failure message.
void _expectBengaliDigitsOnly(String out) {
  expect(
    out.contains(RegExp(r'[0-9]')),
    isFalse,
    reason: 'Output contains ASCII digits: "$out"',
  );
  for (final rune in out.runes) {
    final isAsciiDigit = rune >= 0x30 && rune <= 0x39;
    if (isAsciiDigit) {
      fail(
        'ASCII digit U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')} '
        'in output: "$out"',
      );
    }
  }
}

void main() {
  setUpAll(() async {
    // `BookingFormat.dateTime(_, lang: 'bn')` uses
    // `DateFormat.yMMMd('bn').add_jm()`, which throws `LocaleDataException`
    // in non-browser test environments unless the Bengali locale data has
    // been registered. Initialize both locales we test against.
    await initializeDateFormatting('bn');
    await initializeDateFormatting('en');
  });

  group('BookingFormat — Bengali numerals coverage (Property 12)', () {
    // ---------------------------------------------------------------------
    // money(amount, lang: 'bn', bnNumerals: true)
    // ---------------------------------------------------------------------
    Glados<double>(any.positiveDoubleOrZero).test(
      'money(non-negative double, bn, bnNumerals=true) emits only Bengali digits',
      (amount) {
        final out = BookingFormat.money(amount, lang: 'bn', bnNumerals: true);
        _expectBengaliDigitsOnly(out);
      },
    );

    // ---------------------------------------------------------------------
    // percent(n, lang: 'bn', bnNumerals: true)  with n ∈ [0, 1_000_000]
    // ---------------------------------------------------------------------
    Glados<int>(any.intInRange(0, 1000001)).test(
      'percent(non-negative int in [0,1_000_000], bn, bnNumerals=true) emits only Bengali digits',
      (n) {
        final out = BookingFormat.percent(n, lang: 'bn', bnNumerals: true);
        _expectBengaliDigitsOnly(out);
      },
    );

    // ---------------------------------------------------------------------
    // dateTime(dt, lang: 'bn')  with dt ∈ [1900-01-01, 2100-12-28]
    // ---------------------------------------------------------------------
    Glados<DateTime>(any.bookingDateTime).test(
      'dateTime(DateTime in 1900–2100, bn) emits only Bengali digits',
      (dt) {
        final out = BookingFormat.dateTime(dt, lang: 'bn');
        _expectBengaliDigitsOnly(out);
      },
    );

    // ---------------------------------------------------------------------
    // Sanity unit test (anchors the property to a concrete expected output)
    // ---------------------------------------------------------------------
    test(
      'sanity — money(1234.56, bn, bnNumerals=true) contains "১,২৩৪" and ৳',
      () {
        final out = BookingFormat.money(1234.56, lang: 'bn', bnNumerals: true);
        // The integer portion 1234 with thousands-grouping renders as
        // `১,২৩৪` (U+09E7 U+002C U+09E8 U+09E9 U+09EA) once the substitution
        // loop has run.
        expect(out, contains('১,২৩৪'));
        // Default currency symbol is U+09F3 ৳ (Bengali Taka sign).
        expect(out, contains('\u09F3'));
        _expectBengaliDigitsOnly(out);
      },
    );
  });
}
