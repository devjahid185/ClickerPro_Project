// lib/features/push/data/push_token_api.dart
//
// Device-token endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + DeviceTokenController):
//   POST /api/devices → { data: deviceToken }   body: {token, platform}
// (No unregister endpoint exists yet — logout-time cleanup is
// fire-and-forget until the backend adds one.)

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/push_token_payload.dart';

class PushTokenApi {
  PushTokenApi(this._client);

  final ApiClient _client;

  Future<void> register(PushTokenPayload payload) async {
    await _client.post(
      '/api/devices',
      body: {'token': payload.token, 'platform': payload.platform},
    );
  }

  Future<void> unregister(String token) async {
    try {
      final encoded = Uri.encodeComponent(token);
      await _client.delete('/api/devices/$encoded');
    } catch (e) {
      // Backend has no delete-token route yet; never block logout on it.
      AppLogger.w('push', 'device unregister unavailable: $e');
    }
  }
}
