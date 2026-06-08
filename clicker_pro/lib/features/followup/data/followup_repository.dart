// lib/features/followup/data/followup_repository.dart
//
// Data layer for follow-ups. Owns API + local-cache access so the
// presentation notifier stays thin (clean-architecture normalization).
// API-first with a SharedPreferences fallback for offline rendering.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../domain/followup.dart';

class FollowupRepository {
  FollowupRepository(this._client);

  final ApiClient _client;
  static const _cacheKey = 'followup_list_v1';

  Future<List<Followup>> list() async {
    try {
      final r = await _client.get('/api/followups') as Map<String, dynamic>;
      final raw = (r['data'] as List?) ?? const <dynamic>[];
      final items =
          raw.cast<Map<String, dynamic>>().map(Followup.fromJson).toList();
      await _saveCache(items);
      return items;
    } catch (_) {
      return _loadCache();
    }
  }

  Future<Followup> create(Followup f) async {
    final r = await _client.post('/api/followups', body: f.toCreateJson())
        as Map<String, dynamic>;
    return Followup.fromJson((r['data'] as Map).cast<String, dynamic>());
  }

  Future<void> setCompleted(String id, bool completed) async {
    await _client.patch('/api/followups/$id', body: {'completed': completed});
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/followups/$id');
  }

  // ── Local cache ──
  Future<void> saveCache(List<Followup> items) => _saveCache(items);

  Future<List<Followup>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Followup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(List<Followup> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
