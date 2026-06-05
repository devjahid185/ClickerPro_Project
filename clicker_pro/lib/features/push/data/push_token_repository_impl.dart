// lib/features/push/data/push_token_repository_impl.dart

import '../domain/push_token_payload.dart';
import '../domain/push_token_repository.dart';
import 'push_token_api.dart';

class PushTokenRepositoryImpl implements PushTokenRepository {
  PushTokenRepositoryImpl({required PushTokenApi api}) : _api = api;

  final PushTokenApi _api;

  @override
  Future<void> register(PushTokenPayload payload) => _api.register(payload);

  @override
  Future<void> unregister(String token) => _api.unregister(token);
}
