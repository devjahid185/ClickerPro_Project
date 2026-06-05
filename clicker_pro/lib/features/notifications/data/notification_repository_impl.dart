// lib/features/notifications/data/notification_repository_impl.dart

import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';
import 'notification_api.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationApi api}) : _api = api;

  final NotificationApi _api;

  @override
  Future<List<AppNotification>> list() => _api.list();

  @override
  Future<void> markRead(String id) => _api.markRead(id);
}
