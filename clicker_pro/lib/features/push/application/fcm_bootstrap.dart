// lib/features/push/application/fcm_bootstrap.dart
//
// Firebase Cloud Messaging bootstrap. Called once after a logged-in
// surface mounts (the dashboard): asks notification permission, fetches
// the device's FCM token, registers it with the backend
// (`POST /api/devices`), and keeps it fresh via onTokenRefresh.
//
// Fail-soft by design: push is an enhancement — any Firebase/permission
// problem is logged and the app continues untouched.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/app_config.dart';
import '../../../core/logging/app_logger.dart';
import 'push_token_providers.dart';

bool _fcmInitialized = false;

Future<void> initPushNotifications(WidgetRef ref) async {
  if (_fcmInitialized) return;
  _fcmInitialized = true;

  try {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.i('push', 'notification permission denied');
      return;
    }

    final controller = ref.read(pushTokenControllerProvider);

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await controller.registerForCurrentPlatform(
        token: token,
        appVersion: AppConfig.appVersionLabel,
      );
      AppLogger.i('push', 'FCM token registered');
    }

    messaging.onTokenRefresh.listen((fresh) {
      controller
          .registerForCurrentPlatform(
            token: fresh,
            appVersion: AppConfig.appVersionLabel,
          )
          .catchError((Object e) {
        AppLogger.w('push', 'token refresh registration failed: $e');
      });
    });
  } catch (e) {
    // Missing google-services config, emulator without Play services, …
    AppLogger.w('push', 'FCM init failed: $e');
  }
}
