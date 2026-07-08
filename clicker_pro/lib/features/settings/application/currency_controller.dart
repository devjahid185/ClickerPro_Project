// lib/features/settings/application/currency_controller.dart
//
// Studio-wide currency + VAT/tax configuration. Persisted locally (the
// studio rarely changes it) and used two ways:
//
//   • sets the process-wide [ActiveCurrency] so every money render across
//     the app shows the studio's own symbol, and
//   • carries the VAT rate + label so invoices can add a tax line that
//     matches the studio's country (VAT / GST / Tax — configurable, since
//     every country's system differs).
//
// English-only for now (per product decision); this is data, not locale.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/format/currency.dart';
import '../../../core/providers.dart';

class CurrencyConfig {
  const CurrencyConfig({
    required this.currency,
    this.vatEnabled = false,
    this.vatRatePct = 0,
    this.vatLabel = 'VAT',
  });

  final Currency currency;

  /// Whether invoices add a tax line at all.
  final bool vatEnabled;

  /// Tax percentage, e.g. `15` for a 15% VAT.
  final double vatRatePct;

  /// What the tax is called in this country: `VAT`, `GST`, `Tax`, `SST`…
  final String vatLabel;

  CurrencyConfig copyWith({
    Currency? currency,
    bool? vatEnabled,
    double? vatRatePct,
    String? vatLabel,
  }) => CurrencyConfig(
    currency: currency ?? this.currency,
    vatEnabled: vatEnabled ?? this.vatEnabled,
    vatRatePct: vatRatePct ?? this.vatRatePct,
    vatLabel: vatLabel ?? this.vatLabel,
  );

  /// The tax amount for a given pre-tax [subtotal].
  double vatOn(num subtotal) =>
      vatEnabled ? subtotal * (vatRatePct / 100.0) : 0;
}

const _kCurrencyCode = 'currency_code';
const _kVatEnabled = 'vat_enabled_cfg';
const _kVatRate = 'vat_rate_pct';
const _kVatLabel = 'vat_label';

class CurrencyController extends AsyncNotifier<CurrencyConfig> {
  @override
  Future<CurrencyConfig> build() async {
    final p = await SharedPreferences.getInstance();
    final cfg = CurrencyConfig(
      currency: currencyByCode(p.getString(_kCurrencyCode)),
      vatEnabled: p.getBool(_kVatEnabled) ?? false,
      vatRatePct: p.getDouble(_kVatRate) ?? 0,
      vatLabel: p.getString(_kVatLabel) ?? 'VAT',
    );
    // Publish immediately so the static money formatter + invoice tax lines
    // use it without a ref.
    ActiveCurrency.value = cfg.currency;
    _publishVat(cfg);
    // Best-effort: converge on the studio's server-side setting so a fresh
    // device (or the web app) picks up the same currency + tax. Offline or a
    // pre-migration server just no-ops and the local prefs value stands.
    unawaited(_hydrateFromServer());
    return cfg;
  }

  /// Mirrors [cfg]'s VAT fields into the process-wide [ActiveVat] holder that
  /// ref-less invoice surfaces read.
  void _publishVat(CurrencyConfig cfg) {
    ActiveVat.enabled = cfg.vatEnabled;
    ActiveVat.ratePct = cfg.vatRatePct;
    ActiveVat.label = cfg.vatLabel;
  }

  void _apply(CurrencyConfig cfg) {
    ActiveCurrency.value = cfg.currency;
    _publishVat(cfg);
    state = AsyncData(cfg);
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  /// Pulls the studio's money settings from the profile and adopts them when
  /// the server actually carries a currency (i.e. it has been set at least
  /// once). Silent on any failure — the local prefs value remains authoritative
  /// so offline and pre-migration servers keep working unchanged.
  Future<void> _hydrateFromServer() async {
    try {
      // Offline-first: never hit the network at startup unless the user is
      // actually signed in. Pre-login (and every widget test) short-circuits
      // here, so boot touches no HttpClient.
      final token = await ref.read(secureStoreProvider).readToken();
      if (token == null || token.isEmpty) return;
      final u = await ref.read(userApiProvider).getProfile();
      final code = (u['currencyCode'] ?? u['currency_code'])?.toString();
      if (code == null || code.isEmpty) return;
      final cfg = CurrencyConfig(
        currency: currencyByCode(code),
        vatEnabled: (u['vatEnabled'] ?? u['vat_enabled']) == true,
        vatRatePct: _toDouble(u['vatRatePct'] ?? u['vat_rate_pct']),
        vatLabel: (u['vatLabel'] ?? u['vat_label'])?.toString() ?? 'VAT',
      );
      final p = await SharedPreferences.getInstance();
      await p.setString(_kCurrencyCode, cfg.currency.code);
      await p.setBool(_kVatEnabled, cfg.vatEnabled);
      await p.setDouble(_kVatRate, cfg.vatRatePct);
      await p.setString(_kVatLabel, cfg.vatLabel);
      _apply(cfg);
    } catch (_) {
      // Offline / endpoint missing — keep the local prefs value.
    }
  }

  /// Best-effort push of the current config to the profile so the server (and
  /// the web app) stay in sync. Failures are swallowed; the next successful
  /// save re-syncs.
  Future<void> _pushToServer(CurrencyConfig cfg) async {
    try {
      await ref.read(userApiProvider).patchProfile(<String, dynamic>{
        'currencyCode': cfg.currency.code,
        'vatEnabled': cfg.vatEnabled,
        'vatRatePct': cfg.vatRatePct,
        'vatLabel': cfg.vatLabel,
      });
    } catch (_) {
      // Offline / pre-migration server — local prefs is authoritative.
    }
  }

  CurrencyConfig get _current =>
      state.value ?? const CurrencyConfig(currency: kDefaultCurrency);

  Future<void> setCurrency(Currency c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrencyCode, c.code);
    ActiveCurrency.value = c;
    final next = _current.copyWith(currency: c);
    state = AsyncData(next);
    unawaited(_pushToServer(next));
  }

  Future<void> setVat({
    bool? enabled,
    double? ratePct,
    String? label,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (enabled != null) await p.setBool(_kVatEnabled, enabled);
    if (ratePct != null) await p.setDouble(_kVatRate, ratePct);
    if (label != null) await p.setString(_kVatLabel, label);
    final next = _current.copyWith(
      vatEnabled: enabled,
      vatRatePct: ratePct,
      vatLabel: label,
    );
    _publishVat(next);
    state = AsyncData(next);
    unawaited(_pushToServer(next));
  }
}

final currencyControllerProvider =
    AsyncNotifierProvider<CurrencyController, CurrencyConfig>(
      CurrencyController.new,
    );

/// The studio's active [Currency], reactive for widgets that want to rebuild
/// when it changes. Falls back to the process-wide active value pre-load.
final activeCurrencyProvider = Provider<Currency>((ref) {
  return ref.watch(currencyControllerProvider).value?.currency ??
      ActiveCurrency.value;
});
