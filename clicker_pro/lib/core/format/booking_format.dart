// lib/core/format/booking_format.dart
//
// Booking-specific locale-aware formatting helpers.
//
// Per design "Format Helper Extensions" (bookings-module/design.md), every
// numeric value rendered on a booking surface MUST flow through one of the
// helpers below so Property 12 (Bengali numerals coverage) holds: when
// `lang == 'bn'` every emitted digit is in U+09E6–U+09EF and there are zero
// ASCII digits in the output.
//
// Digit substitution is delegated to [toBengaliDigits] in number_format.dart;
// this file does NOT re-implement the U+09E6–U+09EF replacement loop.

import 'package:intl/intl.dart';

import 'number_format.dart';

class BookingFormat {
  BookingFormat._();

  /// Money formatting that respects Bengali numerals when locale=bn AND the
  /// toggle is on. The currency symbol defaults to U+09F3 (৳ Bengali Taka).
  ///
  /// Returns e.g. `"৳ 12,500"` (en) or `"৳ ১২,৫০০"` (bn + bnNumerals).
  static String money(
    num amount, {
    required String lang,
    required bool bnNumerals,
    String currencySymbol = '\u09F3', // ৳
  }) {
    final base = NumberFormat.decimalPattern(lang).format(amount);
    final digitsApplied = (lang == 'bn' && bnNumerals)
        ? toBengaliDigits(base)
        : base;
    return '$currencySymbol $digitsApplied';
  }

  /// Percentage rendering, e.g. `"65%"` for en or `"৬৫%"` for bn+bnNumerals.
  static String percent(
    int p, {
    required String lang,
    required bool bnNumerals,
  }) {
    final s = (lang == 'bn' && bnNumerals)
        ? toBengaliDigits(p.toString())
        : p.toString();
    return '$s%';
  }

  /// Converts a stored `"HH:mm"` clock string to a 12-hour label with an
  /// AM/PM suffix, e.g. `"17:00"` → `"5 PM"`, `"12:00"` → `"12 PM"` (noon),
  /// `"00:00"` → `"12 AM"` (midnight), `"18:30"` → `"6:30 PM"`.
  ///
  /// The `:00` minutes are dropped for a compact result. Falls back to the
  /// raw string if it doesn't parse. When `lang == 'bn'` the numeric part is
  /// rendered in Bengali numerals; the AM/PM marker stays Latin (there is no
  /// standard Bengali abbreviation and studios read "AM/PM" as-is).
  static String clockTime(String hhmm, {String lang = 'en'}) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return hhmm;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = m == 0 ? '' : ':${parts[1]}';
    final digits = lang == 'bn' ? toBengaliDigits('$h12$mm') : '$h12$mm';
    return '$digits $period';
  }

  /// A `"HH:mm"`→`"HH:mm"` range rendered in 12-hour form, e.g.
  /// `"12:00"`,`"17:00"` → `"12 PM – 5 PM"`. Used on booking cards and detail.
  static String clockRange(
    String startHhmm,
    String endHhmm, {
    String lang = 'en',
    String separator = ' – ',
  }) =>
      '${clockTime(startHhmm, lang: lang)}$separator${clockTime(endHhmm, lang: lang)}';

  /// Date+time render for booking timeline, e.g. `"Jan 5, 2025 17:30"`.
  ///
  /// Time is shown in 24-hour format (`add_Hm`), not 12-hour AM/PM.
  /// When `lang == 'bn'` Bengali numerals are always applied so Property 12
  /// holds for every digit emitted (date numbers, time numbers, year).
  static String dateTime(DateTime dt, {required String lang}) {
    final formatted = DateFormat.yMMMd(lang).add_Hm().format(dt.toLocal());
    return lang == 'bn' ? toBengaliDigits(formatted) : formatted;
  }

  /// Relative time within 24 hours (e.g. `"5 minutes ago"`, `"in 2 hours"`),
  /// otherwise falls back to the absolute [dateTime] render.
  ///
  /// Locale-aware: en uses English labels; bn uses hand-rolled Bengali
  /// labels with Bengali numerals applied so every digit is in U+09E6–U+09EF.
  static String relative(DateTime dt, {required String lang, DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(dt);
    if (diff.inHours.abs() < 24) {
      return _relativeShort(diff, lang);
    }
    return dateTime(dt, lang: lang);
  }

  // --- internal --------------------------------------------------------

  static String _relativeShort(Duration diff, String lang) {
    final isPast = !diff.isNegative; // diff = now - dt; positive => past
    final absSeconds = diff.inSeconds.abs();
    final absMinutes = diff.inMinutes.abs();
    final absHours = diff.inHours.abs();

    String numberStr(int n) =>
        lang == 'bn' ? toBengaliDigits(n.toString()) : n.toString();

    if (absSeconds < 60) {
      return 'just now';
    }
    if (absMinutes < 60) {
      final n = numberStr(absMinutes);
      if (lang == 'bn') {
        return isPast ? '$n min ago' : 'in $n min';
      }
      final unit = absMinutes == 1 ? 'minute' : 'minutes';
      return isPast ? '$n $unit ago' : 'in $n $unit';
    }
    // absHours < 24
    final n = numberStr(absHours);
    if (lang == 'bn') {
      return isPast ? '$n hr ago' : 'in $n hr';
    }
    final unit = absHours == 1 ? 'hour' : 'hours';
    return isPast ? '$n $unit ago' : 'in $n $unit';
  }
}
