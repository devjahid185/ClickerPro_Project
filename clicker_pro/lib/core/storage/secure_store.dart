// lib/core/storage/secure_store.dart
//
// Secure token storage backed by flutter_secure_storage (iOS Keychain /
// Android Keystore). Thin wrapper so call-sites stay decoupled from the
// platform plugin.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'kv_store.dart';

class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: KvKeys.authToken);

  Future<void> writeToken(String token) =>
      _storage.write(key: KvKeys.authToken, value: token);

  Future<void> clearToken() => _storage.delete(key: KvKeys.authToken);
}
