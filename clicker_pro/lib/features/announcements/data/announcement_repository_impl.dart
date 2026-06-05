import '../domain/announcement.dart';
import '../domain/announcement_repository.dart';
import 'announcement_api.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({required AnnouncementApi api}) : _api = api;

  final AnnouncementApi _api;

  @override
  Future<List<Announcement>> list() => _api.list();

  @override
  Future<Announcement> create(Announcement draft) => _api.create(draft);

  @override
  Future<Announcement> update(String id, Map<String, dynamic> fields) =>
      _api.update(id, fields);

  @override
  Future<void> remove(String id) => _api.remove(id);

  @override
  Future<void> markRead(String id) => _api.markRead(id);
}
