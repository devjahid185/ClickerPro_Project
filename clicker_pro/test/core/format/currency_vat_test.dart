// Unit tests for the multi-country currency + VAT helpers that drive money
// rendering and the invoice tax line.

import 'package:clicker_pro/core/format/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency.wrap', () {
    const bdt = Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka');
    const vnd = Currency(
      code: 'VND',
      symbol: '₫',
      name: 'Vietnamese Dong',
      symbolBefore: false,
    );

    test('leading symbol, no space by default (BDT unchanged)', () {
      expect(bdt.wrap('1,500'), '৳1,500');
    });

    test('leading symbol with space when spaced', () {
      expect(bdt.wrap('1,500', spaced: true), '৳ 1,500');
    });

    test('trailing symbol is always spaced, ignoring the flag', () {
      expect(vnd.wrap('1,500'), '1,500 ₫');
      expect(vnd.wrap('1,500', spaced: true), '1,500 ₫');
    });
  });

  group('currencyByCode', () {
    test('resolves known codes case-insensitively', () {
      expect(currencyByCode('usd').code, 'USD');
      expect(currencyByCode('EUR').symbol, '€');
    });

    test('falls back to BDT for null/empty/unknown', () {
      expect(currencyByCode(null).code, 'BDT');
      expect(currencyByCode('').code, 'BDT');
      expect(currencyByCode('ZZZ').code, 'BDT');
    });
  });

  group('ActiveVat', () {
    tearDown(() {
      // Reset the process-wide holder so tests don't leak into each other.
      ActiveVat.enabled = false;
      ActiveVat.ratePct = 0;
      ActiveVat.label = 'VAT';
    });

    test('off by default → no tax, no line', () {
      expect(ActiveVat.applies, isFalse);
      expect(ActiveVat.on(5000), 0);
    });

    test('enabled with a 0 rate does not apply (no "VAT 0%" line)', () {
      ActiveVat.enabled = true;
      ActiveVat.ratePct = 0;
      expect(ActiveVat.applies, isFalse);
      expect(ActiveVat.on(5000), 0);
    });

    test('computes tax on a subtotal when applied', () {
      ActiveVat.enabled = true;
      ActiveVat.ratePct = 15;
      expect(ActiveVat.applies, isTrue);
      expect(ActiveVat.on(5000), 750);
    });

    test('lineLabel trims a whole rate and keeps the studio label', () {
      ActiveVat.enabled = true;
      ActiveVat.ratePct = 15;
      ActiveVat.label = 'GST';
      expect(ActiveVat.lineLabel, 'GST 15%');
    });

    test('lineLabel keeps a fractional rate', () {
      ActiveVat.ratePct = 7.5;
      expect(ActiveVat.lineLabel, 'VAT 7.5%');
    });
  });
}
