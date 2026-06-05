// lib/features/notifications/data/notification_api.dart
//
// Wire-level methods for `/api/notifications`।
//
//   GET   /api/notifications         → list (auth required)
//   PATCH /api/notifications/read    → mark a single id read

import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> list() async {
    final r = await _client.get('/api/notifications') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  Future<void> markRead(String notificationId) async {
    await _client.patch(
      '/api/notifications/read',
      body: {'notificationId': notificationId},
    );
  }
}
