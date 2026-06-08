// lib/features/petty_cash/data/petty_cash_repository.dart
//
// Data layer for petty cash. Owns all API + local-cache access so the
// presentation notifier stays thin (clean-architecture normalization).
// API-first with a SharedPreferences fallback for offline rendering.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../domain/petty_cash_entry.dart';

class PettyCashRepository {
  PettyCashRepository(this._client);

  final ApiClient _client;
  static const _cacheKey = 'petty_cash_list_v1';

  /// Fetch from the server; fall back to cache when offline.
  Future<List<PettyCashEntry>> list() async {
    try {
      final r = await _client.get('/api/petty-cash') as Map<String, dynamic>;
      final raw = (r['data'] as List?) ?? const <dynamic>[];
      final items = raw
          .cast<Map<String, dynamic>>()
          .map(PettyCashEntry.fromJson)
          .toList();
      await _saveCache(items);
      return items;
    } catch (_) {
      return _loadCache();
    }
  }

  Future<PettyCashEntry> create(PettyCashEntry entry) async {
    final r = await _client.post('/api/petty-cash', body: entry.toCreateJson())
        as Map<String, dynamic>;
    return PettyCashEntry.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/petty-cash/$id');
  }

  // ── Local cache ──
  Future<void> saveCache(List<PettyCashEntry> items) => _saveCache(items);

  Future<List<PettyCashEntry>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PettyCashEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(List<PettyCashEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
