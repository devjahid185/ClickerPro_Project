// lib/features/settings/domain/preferences_repository.dart

class NotificationPrefs {
  const NotificationPrefs({
    this.eventReminders = true,
    this.paymentDue = true,
    this.teamMessages = true,
    this.announcements = true,
    this.marketing = false,
  });

  final bool eventReminders;
  final bool paymentDue;
  final bool teamMessages;
  final bool announcements;
  final bool marketing;

  NotificationPrefs copyWith({
    bool? eventReminders,
    bool? paymentDue,
    bool? teamMessages,
    bool? announcements,
    bool? marketing,
  }) => NotificationPrefs(
    eventReminders: eventReminders ?? this.eventReminders,
    paymentDue: paymentDue ?? this.paymentDue,
    teamMessages: teamMessages ?? this.teamMessages,
    announcements: announcements ?? this.announcements,
    marketing: marketing ?? this.marketing,
  );

  static const defaults = NotificationPrefs();
}

abstract class PreferencesRepository {
  Future<String> getLanguage();
  Future<void> setLanguage(String code);
  Stream<String> watchLanguage();

  Future<NotificationPrefs> getNotificationPrefs(String userId);
  Future<void> setNotificationPrefs(String userId, NotificationPrefs prefs);
  Stream<NotificationPrefs> watchNotificationPrefs(String userId);

  Future<bool> getDistributionEnabled(String userId);
  Future<void> setDistributionEnabled(String userId, bool value);

  Future<bool> getVatEnabled(String userId);
  Future<void> setVatEnabled(String userId, bool value);

  Future<bool> getBengaliNumerals(String userId);
  Future<void> setBengaliNumerals(String userId, bool value);
}
