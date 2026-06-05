// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_dao.dart';

// ignore_for_file: type=lint
mixin _$PreferencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserPreferencesTableTable get userPreferencesTable =>
      attachedDatabase.userPreferencesTable;
  $NotificationPreferencesTableTable get notificationPreferencesTable =>
      attachedDatabase.notificationPreferencesTable;
  PreferencesDaoManager get managers => PreferencesDaoManager(this);
}

class PreferencesDaoManager {
  final _$PreferencesDaoMixin _db;
  PreferencesDaoManager(this._db);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(
        _db.attachedDatabase,
        _db.userPreferencesTable,
      );
  $$NotificationPreferencesTableTableTableManager
  get notificationPreferencesTable =>
      $$NotificationPreferencesTableTableTableManager(
        _db.attachedDatabase,
        _db.notificationPreferencesTable,
      );
}
