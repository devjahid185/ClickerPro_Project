// test/features/push/push_token_test.dart

import 'package:clicker_pro/features/push/application/push_token_providers.dart';
import 'package:clicker_pro/features/push/domain/push_token_payload.dart';
import 'package:clicker_pro/features/push/domain/push_token_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePushRepo implements PushTokenRepository {
  PushTokenPayload? lastRegister;
  String? lastUnregister;

  @override
  Future<void> register(PushTokenPayload payload) async {
    lastRegister = payload;
  }

  @override
  Future<void> unregister(String token) async {
    lastUnregister = token;
  }
}

void main() {
  group('PushTokenPayload.toJson', () {
    test('omits null fields', () {
      const p = PushTokenPayload(token: 'abc', platform: 'android');
      expect(p.toJson(), equals({'token': 'abc', 'platform': 'android'}));
    });

    test('includes appVersion + language when set', () {
      const p = PushTokenPayload(
        token: 'abc',
        platform: 'ios',
        appVersion: '1.0.0',
        language: 'bn',
      );
      expect(
        p.toJson(),
        equals({
          'token': 'abc',
          'platform': 'ios',
          'appVersion': '1.0.0',
          'language': 'bn',
        }),
      );
    });

    test('equality + hashCode honour all fields', () {
      const a = PushTokenPayload(
        token: 't',
        platform: 'android',
        appVersion: '1',
        language: 'en',
      );
      const b = PushTokenPayload(
        token: 't',
        platform: 'android',
        appVersion: '1',
        language: 'en',
      );
      const c = PushTokenPayload(
        token: 't',
        platform: 'ios',
        appVersion: '1',
        language: 'en',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('PushTokenController', () {
    test('registerForCurrentPlatform forwards to repo with platform', () async {
      final repo = _FakePushRepo();
      final ctl = PushTokenController(repo);

      await ctl.registerForCurrentPlatform(
        token: 'fcm-token-123',
        appVersion: '2.0.0',
        language: 'bn',
      );

      expect(repo.lastRegister, isNotNull);
      expect(repo.lastRegister!.token, 'fcm-token-123');
      expect(repo.lastRegister!.appVersion, '2.0.0');
      expect(repo.lastRegister!.language, 'bn');
      // Platform is one of the known constants.
      expect(repo.lastRegister!.platform, anyOf('android', 'ios', 'web'));
    });

    test('unregister forwards token verbatim', () async {
      final repo = _FakePushRepo();
      final ctl = PushTokenController(repo);

      await ctl.unregister('fcm-token-bye');

      expect(repo.lastUnregister, 'fcm-token-bye');
    });
  });
}
