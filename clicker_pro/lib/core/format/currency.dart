// lib/core/format/currency.dart
//
// Multi-country currency support. Graphy7 is used by studios worldwide,
// so every money value must render in the studio's own currency instead of
// a hardcoded ৳ (BDT). This file is the single source of truth for:
//
//   • the [Currency] value type (code, symbol, decimals, symbol position),
//   • a registry of the currencies we ship ([kCurrencies]),
//   • the process-wide [ActiveCurrency] the static money formatter reads.
//
// Design note: the money formatter in `booking_format.dart` is a *static*
// helper called from ~90 places, so it can't read a Riverpod provider. We
// keep a lightweight mutable holder ([ActiveCurrency.value]) that the app
// sets once from the signed-in user's preference (see currencyProvider).
// Until it's set it defaults to BDT, so nothing regresses.

import 'package:intl/intl.dart';

/// An ISO-4217 currency plus the presentation details we render with.
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimals = 2,
    this.symbolBefore = true,
  });

  /// ISO-4217 code, e.g. `BDT`, `USD`, `EUR`.
  final String code;

  /// Display symbol, e.g. `৳`, `$`, `€`. May be multi-char (`RM`, `Rp`).
  final String symbol;

  /// Human name for pickers, e.g. `Bangladeshi Taka`.
  final String name;

  /// Fraction digits. Most currencies use 2; JPY/KRW/VND/IDR use 0.
  final int decimals;

  /// Whether the symbol sits before the amount (`$100`) or after (`100 ₫`).
  final bool symbolBefore;

  /// Formats [amount] with grouping + this currency's decimals and symbol.
  /// [digits] lets the caller substitute Bengali numerals without this
  /// method depending on the locale layer.
  String format(num amount, {String Function(String)? digits}) {
    final pattern = NumberFormat.currency(
      // en_US grouping is a safe, widely-recognised default; we attach our
      // own symbol so the locale's own currency sign is never used.
      locale: 'en_US',
      symbol: '',
      decimalDigits: decimals,
    );
    var body = pattern.format(amount).trim();
    if (digits != null) body = digits(body);
    return symbolBefore ? '$symbol$body' : '$body $symbol';
  }

  /// Wraps an already-grouped numeric [body] with this currency's symbol in
  /// the correct position. Callers keep their own grouping/decimals (some
  /// studios use lakh grouping, some show paisa) and only delegate symbol
  /// placement here, so BDT renders byte-for-byte as it did before.
  ///
  /// [spaced] inserts a space between a leading symbol and the amount
  /// (`৳ 1,500` vs `৳1,500`). A trailing symbol (e.g. VND `1,500 ₫`) is
  /// always spaced regardless of the flag.
  String wrap(String body, {bool spaced = false}) {
    if (!symbolBefore) return '$body $symbol';
    return spaced ? '$symbol $body' : '$symbol$body';
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Currencies shipped in the picker. Ordered with the common studio markets
/// first, then broadly alphabetical. Extend freely — nothing else hardcodes
/// a currency list.
const List<Currency> kCurrencies = [
  Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
  Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
  Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
  Currency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
  Currency(code: 'NPR', symbol: 'रू', name: 'Nepalese Rupee'),
  Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
  Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
  Currency(code: 'QAR', symbol: 'ر.ق', name: 'Qatari Riyal'),
  Currency(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar', decimals: 3),
  Currency(code: 'OMR', symbol: 'ر.ع.', name: 'Omani Rial', decimals: 3),
  Currency(code: 'BHD', symbol: '.د.ب', name: 'Bahraini Dinar', decimals: 3),
  Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', decimals: 0),
  Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  Currency(
    code: 'VND',
    symbol: '₫',
    name: 'Vietnamese Dong',
    decimals: 0,
    symbolBefore: false,
  ),
  Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', decimals: 0),
  Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won', decimals: 0),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
  Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
  Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
  Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
  Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
  Currency(code: 'MXN', symbol: 'Mex\$', name: 'Mexican Peso'),
];

/// Default until the signed-in user's preference loads.
const Currency kDefaultCurrency = Currency(
  code: 'BDT',
  symbol: '৳',
  name: 'Bangladeshi Taka',
);

/// Looks up a currency by ISO code (case-insensitive). Falls back to BDT so
/// a stale/unknown code never crashes a money render.
Currency currencyByCode(String? code) {
  if (code == null || code.isEmpty) return kDefaultCurrency;
  final upper = code.toUpperCase();
  for (final c in kCurrencies) {
    if (c.code == upper) return c;
  }
  return kDefaultCurrency;
}

/// Process-wide active currency the static money formatter reads. Set once
/// from the user's preference on sign-in; defaults to BDT so pre-login and
/// offline renders still work.
class ActiveCurrency {
  ActiveCurrency._();

  static Currency value = kDefaultCurrency;
}

/// Process-wide active VAT/tax setting. Invoice surfaces (on-screen paper, PDF,
/// WhatsApp, clipboard) read this without a Riverpod ref for the same reason
/// [ActiveCurrency] exists — some are plain widgets or ref-less helpers. The
/// currency controller publishes it from the studio's saved [CurrencyConfig].
/// Defaults to off, so invoices render exactly as before until a studio turns
/// tax on.
class ActiveVat {
  ActiveVat._();

  /// Whether invoices add a tax line at all.
  static bool enabled = false;

  /// Tax percentage, e.g. `15` for 15%.
  static double ratePct = 0;

  /// What the tax is called here: `VAT`, `GST`, `Tax`, `SST`…
  static String label = 'VAT';

  /// Whether a tax line should actually be drawn (enabled with a real rate).
  static bool get applies => enabled && ratePct > 0;

  /// The tax amount for a pre-tax [subtotal]; `0` when it doesn't apply.
  static double on(num subtotal) =>
      applies ? subtotal * (ratePct / 100.0) : 0;

  /// e.g. `VAT 15%` — the label shown on a tax line.
  static String get lineLabel {
    final r = ratePct % 1 == 0 ? ratePct.toStringAsFixed(0) : ratePct.toString();
    return '$label $r%';
  }
}
