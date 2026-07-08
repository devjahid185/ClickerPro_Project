// lib/core/format/number_format.dart
//
// Locale-aware number/date formatting. Bengali numerals are an opt-in.

import 'package:intl/intl.dart';

const _bnZero = 0x09E6; // ০
final _asciiDigitPattern = RegExp(r'\d');

/// Replaces every ASCII digit (0-9) in [input] with the corresponding
/// Bengali digit (U+09E6 ০ through U+09EF ৯). Non-digit characters are
/// preserved verbatim. This is the single source of truth for digit
/// substitution across the app — every locale-aware formatter that needs
/// Bengali numerals delegates here so the substitution loop is never
/// duplicated.
String toBengaliDigits(String input) {
  return input.replaceAllMapped(
    _asciiDigitPattern,
    (m) => String.fromCharCode(_bnZero + int.parse(m[0]!)),
  );
}

String formatNumber(
  num value, {
  required String lang,
  bool bengaliNumerals = false,
}) {
  final f = NumberFormat.decimalPattern(lang);
  final raw = f.format(value);
  if (lang == 'bn' && bengaliNumerals) {
    return toBengaliDigits(raw);
  }
  return raw;
}

String formatDate(DateTime date, {required String lang}) {
  return DateFormat.yMMMMd(lang).format(date);
}
