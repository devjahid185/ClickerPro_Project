import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notification_preferences_table.dart';
import '../tables/user_preferences_table.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [UserPreferencesTable, NotificationPreferencesTable])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  Stream<UserPreferencesRow?> watchUserPrefs(String userId) => (select(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId))).watchSingleOrNull();

  Future<UserPreferencesRow?> getUserPrefs(String userId) => (select(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Future<void> upsertUserPrefs(UserPreferencesTableCompanion row) async {
    await into(userPreferencesTable).insertOnConflictUpdate(row);
  }

  Stream<NotificationPreferencesRow?> watchNotifPrefs(String userId) => (select(
    notificationPreferencesTable,
  )..where((t) => t.userId.equals(userId))).watchSingleOrNull();

  Future<NotificationPreferencesRow?> getNotifPrefs(String userId) => (select(
    notificationPreferencesTable,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Future<void> upsertNotifPrefs(
    NotificationPreferencesTableCompanion row,
  ) async {
    await into(notificationPreferencesTable).insertOnConflictUpdate(row);
  }
}
