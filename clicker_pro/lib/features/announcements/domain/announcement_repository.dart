import 'announcement.dart';

abstract class AnnouncementRepository {
  /// `GET /api/announcements` — studio-scoped list, descending by createdAt.
  Future<List<Announcement>> list();

  /// `POST /api/announcements` — returns the persisted record (with id).
  Future<Announcement> create(Announcement draft);

  /// `PATCH /api/announcements/:id` — toggle pin, update expiry, etc.
  Future<Announcement> update(String id, Map<String, dynamic> fields);

  /// `DELETE /api/announcements/:id` — owner-scoped.
  Future<void> remove(String id);

  /// `POST /api/announcements/:id/read` — mark as read by current user.
  Future<void> markRead(String id);
}
