// lib/features/settings/data/preferences_repository_impl.dart

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/preferences_dao.dart';
import '../../../core/storage/kv_store.dart';
import '../domain/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl({required AppDatabase db, required KvStore kv})
    : _db = db,
      _kv = kv;

  final AppDatabase _db;
  final KvStore _kv;
  PreferencesDao get _prefs => _db.preferencesDao;

  Stream<String>? _langStream;

  Future<UserPreferencesRow> _ensurePrefs(String userId) async {
    final existing = await _prefs.getUserPrefs(userId);
    if (existing != null) return existing;
    await _prefs.upsertUserPrefs(
      UserPreferencesTableCompanion.insert(userId: userId),
    );
    return (await _prefs.getUserPrefs(userId))!;
  }

  Future<NotificationPreferencesRow> _ensureNotifPrefs(String userId) async {
    final existing = await _prefs.getNotifPrefs(userId);
    if (existing != null) return existing;
    await _prefs.upsertNotifPrefs(
      NotificationPreferencesTableCompanion.insert(userId: userId),
    );
    return (await _prefs.getNotifPrefs(userId))!;
  }

  @override
  Future<String> getLanguage() async =>
      (await _kv.readString(KvKeys.appLang)) ?? 'en';

  @override
  Future<void> setLanguage(String code) =>
      _kv.writeString(KvKeys.appLang, code);

  @override
  Stream<String> watchLanguage() {
    // SharedPreferences doesn't natively stream — emit on every getLanguage poll
    // via a lazy controller. The LanguageController updates state imperatively
    // after setLanguage so this stream stays a fallback.
    return _langStream ??= Stream<String>.fromFuture(
      getLanguage(),
    ).asBroadcastStream();
  }

  @override
  Future<NotificationPrefs> getNotificationPrefs(String userId) async {
    final row = await _ensureNotifPrefs(userId);
    return NotificationPrefs(
      eventReminders: row.eventReminders,
      paymentDue: row.paymentDue,
      teamMessages: row.teamMessages,
      announcements: row.announcements,
      marketing: row.marketing,
    );
  }

  @override
  Future<void> setNotificationPrefs(
    String userId,
    NotificationPrefs prefs,
  ) async {
    await _prefs.upsertNotifPrefs(
      NotificationPreferencesTableCompanion(
        userId: Value(userId),
        eventReminders: Value(prefs.eventReminders),
        paymentDue: Value(prefs.paymentDue),
        teamMessages: Value(prefs.teamMessages),
        announcements: Value(prefs.announcements),
        marketing: Value(prefs.marketing),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<NotificationPrefs> watchNotificationPrefs(String userId) {
    return _prefs.watchNotifPrefs(userId).map((row) {
      if (row == null) return NotificationPrefs.defaults;
      return NotificationPrefs(
        eventReminders: row.eventReminders,
        paymentDue: row.paymentDue,
        teamMessages: row.teamMessages,
        announcements: row.announcements,
        marketing: row.marketing,
      );
    });
  }

  @override
  Future<bool> getDistributionEnabled(String userId) async {
    final row = await _ensurePrefs(userId);
    return row.distributionEnabled;
  }

  @override
  Future<void> setDistributionEnabled(String userId, bool value) async {
    await _ensurePrefs(userId);
    await _prefs.upsertUserPrefs(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        distributionEnabled: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<bool> getVatEnabled(String userId) async {
    final row = await _ensurePrefs(userId);
    return row.vatEnabled;
  }

  @override
  Future<void> setVatEnabled(String userId, bool value) async {
    await _ensurePrefs(userId);
    await _prefs.upsertUserPrefs(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        vatEnabled: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<bool> getBengaliNumerals(String userId) async {
    final row = await _ensurePrefs(userId);
    return row.bengaliNumerals;
  }

  @override
  Future<void> setBengaliNumerals(String userId, bool value) async {
    await _ensurePrefs(userId);
    await _prefs.upsertUserPrefs(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        bengaliNumerals: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
