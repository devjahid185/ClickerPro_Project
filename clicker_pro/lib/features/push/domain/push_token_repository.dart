// lib/features/push/domain/push_token_repository.dart

import 'push_token_payload.dart';

abstract class PushTokenRepository {
  /// `POST /api/devices/register` — idempotent upsert on (userId, token)।
  Future<void> register(PushTokenPayload payload);

  /// `DELETE /api/devices/:token` — call from logout / "remove this
  /// device" UI।
  Future<void> unregister(String token);
}
