// lib/core/storage/kv_store.dart
//
// Typed wrapper over SharedPreferences. Strictly limited to a small set of keys
// at the Foundation slice (Requirement 6.8). Anything else lives in Drift.

import 'package:shared_preferences/shared_preferences.dart';

class KvKeys {
  KvKeys._();
  static const String authToken = 'auth_token';
  static const String appLang = 'app_lang';
  static const String onboardingComplete = 'onboarding_complete';
  static const String pendingDeleteUntil = 'pending_delete_until';
  static const String appThemeMode = 'app_theme_mode';
  static const String seenBroadcastIds = 'seen_broadcast_ids';

  static const Set<String> _allowed = {
    authToken,
    appLang,
    onboardingComplete,
    pendingDeleteUntil,
    appThemeMode,
    seenBroadcastIds,
  };
  static bool isAllowed(String key) => _allowed.contains(key);
}

class KvStore {
  KvStore({SharedPreferences? prefs}) : _override = prefs;
  final SharedPreferences? _override;

  Future<SharedPreferences> _prefs() async =>
      _override ?? await SharedPreferences.getInstance();

  void _assertAllowed(String key) {
    assert(
      KvKeys.isAllowed(key),
      'KvStore key "$key" is not in the allowed set. Add it to KvKeys or use Drift.',
    );
  }

  Future<String?> readString(String key) async {
    _assertAllowed(key);
    return (await _prefs()).getString(key);
  }

  Future<void> writeString(String key, String value) async {
    _assertAllowed(key);
    await (await _prefs()).setString(key, value);
  }

  Future<bool?> readBool(String key) async {
    _assertAllowed(key);
    return (await _prefs()).getBool(key);
  }

  Future<void> writeBool(String key, bool value) async {
    _assertAllowed(key);
    await (await _prefs()).setBool(key, value);
  }

  Future<void> remove(String key) async {
    _assertAllowed(key);
    await (await _prefs()).remove(key);
  }

  Future<void> clearAll() async {
    final p = await _prefs();
    for (final k in KvKeys._allowed) {
      await p.remove(k);
    }
  }
}
