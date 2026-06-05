// lib/features/notifications/domain/notification_repository.dart

import 'app_notification.dart';

abstract class NotificationRepository {
  /// `GET /api/notifications` — caller-scoped descending sentAt list।
  Future<List<AppNotification>> list();

  /// `PATCH /api/notifications/read` — flip a single notification's
  /// `read` flag to true।  No-op locally if the row was already read।
  Future<void> markRead(String notificationId);
}
