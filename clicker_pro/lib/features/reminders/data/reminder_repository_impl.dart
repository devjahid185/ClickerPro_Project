import '../domain/reminder.dart';
import 'reminder_api.dart';

class ReminderRepositoryImpl {
  ReminderRepositoryImpl({required ReminderApi api}) : _api = api;

  final ReminderApi _api;

  Future<List<Reminder>> list() => _api.list();

  Future<Reminder> create(Reminder draft) => _api.create(draft);

  Future<void> update(Reminder reminder) => _api.update(reminder);

  Future<void> delete(String id) => _api.delete(id);
}
