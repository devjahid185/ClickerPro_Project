// lib/features/tools/presentation/calculator_screen.dart
//
// A simple, self-contained calculator for quick studio maths (deposits,
// splits, change). No packages — a small expression evaluator handles + − × ÷
// and %, with a running display.

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expr = '';
  String _result = '';

  void _tap(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
          _result = '';
          break;
        case '⌫':
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          break;
        case '=':
          _result = _evaluate(_expr);
          break;
        default:
          _expr += key;
      }
    });
  }

  /// Evaluates a flat `+ − × ÷ %` expression left-to-right with correct
  /// operator precedence (× ÷ before + −). Returns '' on any parse error.
  String _evaluate(String raw) {
    if (raw.trim().isEmpty) return '';
    try {
      final normalized = raw
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');
      final value = _ExprParser(normalized).parse();
      if (value.isNaN || value.isInfinite) return 'Error';
      // Trim trailing .0 for whole numbers.
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value
          .toStringAsFixed(4)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    } catch (_) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['00', '0', '.', '='],
    ];

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Calculator',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expr.isEmpty ? '0' : _expr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Keypad
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: [
                for (final row in keys)
                  Row(
                    children: [
                      for (final k in row) _key(k),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _key(String k) {
    final isOp = ['÷', '×', '−', '+', '='].contains(k);
    final isFn = ['C', '⌫', '%'].contains(k);
    final bg = k == '='
        ? AppColors.orange
        : isOp
            ? AppColors.orange.withValues(alpha: 0.14)
            : isFn
                ? AppColors.surface
                : AppColors.voidElevated;
    final fg = k == '='
        ? Colors.white
        : isOp
            ? AppColors.orange
            : AppColors.film;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _tap(k),
            child: Container(
              height: 62,
              alignment: Alignment.center,
              child: Text(
                k,
                style: TextStyle(
                  color: fg,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny recursive-descent parser for `+ − * / %` with correct precedence.
/// `%` is treated as "percent of the running value" only in the simple form
/// `a % b` = a/100*b — here we keep it as modulo-free percentage: `a%` → a/100.
class _ExprParser {
  _ExprParser(this._s);
  final String _s;
  int _pos = 0;

  double parse() {
    final v = _parseAddSub();
    if (_pos != _s.length) throw const FormatException('trailing');
    return v;
  }

  double _parseAddSub() {
    var v = _parseMulDiv();
    while (_pos < _s.length) {
      final c = _s[_pos];
      if (c == '+') {
        _pos++;
        v += _parseMulDiv();
      } else if (c == '-') {
        _pos++;
        v -= _parseMulDiv();
      } else {
        break;
      }
    }
    return v;
  }

  double _parseMulDiv() {
    var v = _parseNumber();
    while (_pos < _s.length) {
      final c = _s[_pos];
      if (c == '*') {
        _pos++;
        v *= _parseNumber();
      } else if (c == '/') {
        _pos++;
        v /= _parseNumber();
      } else {
        break;
      }
    }
    return v;
  }

  double _parseNumber() {
    final start = _pos;
    // Optional leading unary minus.
    if (_pos < _s.length && _s[_pos] == '-') _pos++;
    while (_pos < _s.length && RegExp(r'[0-9.]').hasMatch(_s[_pos])) {
      _pos++;
    }
    // Percent suffix: divide by 100.
    var isPercent = false;
    if (_pos < _s.length && _s[_pos] == '%') {
      isPercent = true;
      _pos++;
    }
    final token = _s.substring(start, isPercent ? _pos - 1 : _pos);
    final n = double.tryParse(token);
    if (n == null) throw const FormatException('number');
    return isPercent ? n / 100 : n;
  }
}
