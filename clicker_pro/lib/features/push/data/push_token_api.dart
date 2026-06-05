// lib/features/push/data/push_token_api.dart

import '../../../core/network/api_client.dart';
import '../domain/push_token_payload.dart';

class PushTokenApi {
  PushTokenApi(this._client);

  final ApiClient _client;

  Future<void> register(PushTokenPayload payload) async {
    await _client.post('/api/devices/register', body: payload.toJson());
  }

  Future<void> unregister(String token) async {
    // Backend's path param is the raw token; URL-encode to be safe in
    // case future tokens carry slashes (unlikely with FCM but cheap)।
    final encoded = Uri.encodeComponent(token);
    await _client.delete('/api/devices/$encoded');
  }
}
