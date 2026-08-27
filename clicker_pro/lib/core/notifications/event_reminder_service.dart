// lib/core/notifications/event_reminder_service.dart
//
// On-device scheduled reminders for upcoming events (MOD-44). When a
// booking is saved we schedule a local notification to fire one hour
// before the event's start time. This is fully offline — the OS holds the
// alarm, so it works without the server, Firebase scheduling, or even a
// network connection.
//
// Fail-soft: every entry point swallows platform errors and logs them, so
// a notification problem can never block saving a booking.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../format/booking_format.dart';
import '../logging/app_logger.dart';

class EventReminderService {
  EventReminderService._();
  static final EventReminderService instance = EventReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Whether the OS granted the POST_NOTIFICATIONS permission on last init.
  /// When false, scheduled reminders will not be shown by the system.
  bool _notificationsAllowed = false;

  /// True once init has run and the notification permission was granted.
  bool get notificationsAllowed => _notificationsAllowed;

  /// How long before the event start the reminder fires.
  static const Duration _lead = Duration(hours: 1);

  static const String _channelId = 'event_reminders';
  static const String _channelName = 'Event Reminders';
  static const String _channelDesc =
      'Reminds you one hour before each booked event.';

  /// Initializes the plugin + Asia/Dhaka timezone and asks for the
  /// notification / exact-alarm permissions. Safe to call repeatedly.
  Future<void> init() async {
    if (_ready) return;
    try {
      tz.initializeTimeZones();
      // The app is international — read the device's own IANA zone so the
      // 1-hour offset is computed against the user's local wall-clock
      // (Asia/Dhaka, Asia/Kolkata, …). Fall back to Dhaka only if the
      // platform lookup fails or returns an unknown zone.
      await _setLocalTimezone();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      final android13 = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Create the notification channel up front. A scheduled alarm posted to
      // a channel that doesn't exist yet is silently dropped on some OEMs —
      // creating it here guarantees the reminder can always be delivered.
      await android13?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Runtime permissions (Android 13+ / 14+ / iOS). Log the grant result so
      // a silent denial (the usual cause of "no notification arrives") is
      // visible in the logs instead of failing invisibly.
      final notifGranted =
          await android13?.requestNotificationsPermission() ?? false;
      // Android 14+ gates full-screen intents behind their own permission.
      await android13?.requestFullScreenIntentPermission();
      final exactGranted =
          await android13?.requestExactAlarmsPermission() ?? false;
      _notificationsAllowed = notifGranted;
      AppLogger.i(
        'reminder',
        'permissions — notifications:$notifGranted exactAlarm:$exactGranted',
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (e, st) {
      AppLogger.w('reminder', 'init failed: $e');
      AppLogger.e('reminder', e, st);
    }
  }

  /// Schedules (or reschedules) the 1-hour-before reminder for a booking.
  ///
  /// [bookingId] keys the notification so re-saving the same booking
  /// replaces the old alarm instead of stacking duplicates. Past events and
  /// events whose reminder time has already passed are skipped silently.
  ///
  /// The reminder fires as a FULL-SCREEN alarm-style notification on Android
  /// (Heaven's spec: "মোবাইলের ফুল স্ক্রিন হবে, ইভেন্ট ডিটেইলস সহ") carrying
  /// the event details — time, venue, client — in an expanded big-text body.
  Future<void> scheduleForBooking({
    required String bookingId,
    required String title,
    required DateTime eventDate,
    required String startTime,
    String? endTime,
    String? venue,
    String? clientName,
    String? clientPhone,
  }) async {
    await init();
    if (!_ready) return;
    // Pick up a permission the user granted after first launch, so a booking
    // saved later still schedules its reminder.
    if (!_notificationsAllowed) await _refreshPermission();
    try {
      final start = _composeStart(eventDate, startTime);
      final fireAt = start.subtract(_lead);
      // Don't schedule something already in the past.
      if (fireAt.isBefore(DateTime.now())) {
        await cancelForBooking(bookingId);
        return;
      }

      final tzFire = tz.TZDateTime.from(fireAt, tz.local);
      final timeLine = endTime == null || endTime.trim().isEmpty
          ? BookingFormat.clockTime(startTime)
          : BookingFormat.clockRange(startTime, endTime);
      // Full event details for the expanded (big-text) notification body.
      final details = <String>[
        'Starts in 1 hour · $timeLine',
        if (venue != null && venue.trim().isNotEmpty) 'Venue: ${venue.trim()}',
        if (clientName != null && clientName.trim().isNotEmpty)
          'Client: ${clientName.trim()}',
        if (clientPhone != null && clientPhone.trim().isNotEmpty)
          'Phone: ${clientPhone.trim()}',
      ].join('\n');
      final collapsed = venue != null && venue.trim().isNotEmpty
          ? 'Starts in 1 hour — ${venue.trim()}'
          : 'Your event starts in 1 hour';

      await _plugin.zonedSchedule(
        _idFor(bookingId),
        '📸 $title',
        collapsed,
        tzFire,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            // Alarm-style: wakes the screen and shows over the lock screen
            // like an incoming call, with the full details expanded.
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(
              details,
              contentTitle: '📸 $title',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      AppLogger.i('reminder', 'scheduled $bookingId for $tzFire');
    } catch (e, st) {
      AppLogger.w('reminder', 'schedule failed for $bookingId: $e');
      AppLogger.e('reminder', e, st);
    }
  }

  /// Fires a reminder ~10 seconds from now so the user can confirm that
  /// notifications actually reach the device (permissions + channel wired).
  /// Returns false if the plugin isn't ready or the permission was denied.
  Future<bool> sendTestNotification() async {
    await init();
    if (!_ready) return false;
    // Re-read the live permission state so "Try again" works right after the
    // user enables notifications in phone Settings (init() only runs once).
    await _refreshPermission();
    if (!_notificationsAllowed) return false;
    try {
      final fireAt = DateTime.now().add(const Duration(seconds: 10));
      await _plugin.zonedSchedule(
        _testId,
        '📸 Test reminder',
        'This is how your 1-hour-before event reminder will look.',
        tz.TZDateTime.from(fireAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            styleInformation: const BigTextStyleInformation(
              'If you see this, event reminders are working. Real reminders '
              'arrive one hour before each booking with the full details.',
              contentTitle: '📸 Test reminder',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      AppLogger.i('reminder', 'test notification scheduled for $fireAt');
      return true;
    } catch (e, st) {
      AppLogger.w('reminder', 'test notification failed: $e');
      AppLogger.e('reminder', e, st);
      return false;
    }
  }

  /// Shows an immediate heads-up notification for server push messages while
  /// the app is open. FCM displays `notification` payloads automatically only
  /// when the app is backgrounded; foreground messages need a local mirror.
  Future<void> showServerPush({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    if (!_ready) return;
    if (!_notificationsAllowed) await _refreshPermission();
    if (!_notificationsAllowed) return;

    try {
      await _plugin.show(
        DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      AppLogger.w('reminder', 'server push display failed: $e');
      AppLogger.e('reminder', e, st);
    }
  }

  /// Re-reads the live notification permission from the OS and, if it isn't
  /// granted yet, requests it again. Updates [_notificationsAllowed] so a
  /// "Try again" after the user flips the toggle in phone Settings sees the
  /// new state instead of the stale value from first init.
  Future<void> _refreshPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        var enabled = await android.areNotificationsEnabled() ?? false;
        if (!enabled) {
          enabled = await android.requestNotificationsPermission() ?? false;
        }
        _notificationsAllowed = enabled;
        return;
      }
      // iOS / other: assume the initial request result still holds.
    } catch (e) {
      AppLogger.w('reminder', 'permission refresh failed: $e');
    }
  }

  /// Reads the device's IANA timezone name and pins it as the local zone
  /// used for all scheduling. International-safe: a user in Kolkata gets
  /// Asia/Kolkata, a user in Dhaka gets Asia/Dhaka. Falls back to Dhaka if
  /// the platform channel fails or hands back a name the tz database
  /// doesn't know, so scheduling always has a valid zone.
  Future<void> _setLocalTimezone() async {
    var zoneName = 'Asia/Dhaka';
    try {
      final deviceZone = await FlutterTimezone.getLocalTimezone();
      if (deviceZone.trim().isNotEmpty) zoneName = deviceZone.trim();
    } catch (e) {
      AppLogger.w('reminder', 'device timezone lookup failed: $e');
    }
    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      // Unknown zone name — fall back to a location that always exists.
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      AppLogger.w('reminder', 'unknown zone "$zoneName", using Asia/Dhaka');
    }
  }

  /// Re-arms the OS alarm for every upcoming booking passed in. This is the
  /// fix for "event আগে notification আসে না": [scheduleForBooking] only runs
  /// when a booking is saved *inside the app*, so bookings that synced from
  /// the server, were made on another device, or predate this feature never
  /// had an alarm. Calling this on app open guarantees every future event
  /// has its 1-hour reminder — past events are skipped by scheduleForBooking.
  ///
  /// Fail-soft per booking: one bad row can't stop the rest from arming.
  Future<int> syncUpcomingReminders(
    Iterable<ReminderBooking> bookings,
  ) async {
    await init();
    if (!_ready) return 0;
    var armed = 0;
    for (final b in bookings) {
      try {
        await scheduleForBooking(
          bookingId: b.id,
          title: b.title,
          eventDate: b.eventDate,
          startTime: b.startTime,
          endTime: b.endTime,
          venue: b.venue,
          clientName: b.clientName,
          clientPhone: b.clientPhone,
        );
        armed++;
      } catch (e) {
        AppLogger.w('reminder', 'sync skip ${b.id}: $e');
      }
    }
    AppLogger.i('reminder', 'synced $armed upcoming reminders');
    return armed;
  }

  /// How many reminders are currently scheduled with the OS — useful for
  /// verifying that saving a booking actually created an alarm.
  Future<int> pendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  /// Cancels any pending reminder for a booking (e.g. on cancel/delete).
  Future<void> cancelForBooking(String bookingId) async {
    try {
      await _plugin.cancel(_idFor(bookingId));
    } catch (e) {
      AppLogger.w('reminder', 'cancel failed for $bookingId: $e');
    }
  }

  /// Combines the event's date with its "HH:mm" start time. Falls back to
  /// 10:00 when the time string is malformed so a reminder is still set.
  DateTime _composeStart(DateTime date, String startTime) {
    final parts = startTime.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 10) : 10;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, h.clamp(0, 23),
        m.clamp(0, 59));
  }

  /// Stable 31-bit notification id derived from the booking id, so saving
  /// the same booking twice updates the same alarm.
  int _idFor(String bookingId) => bookingId.hashCode & 0x7fffffff;

  /// Fixed id for the test notification — a value real booking ids won't hit.
  static const int _testId = 2147483646; // max int32 - 1
}

/// Minimal booking shape [EventReminderService.syncUpcomingReminders] needs,
/// so the notification layer doesn't depend on the full Booking domain model.
class ReminderBooking {
  const ReminderBooking({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.startTime,
    this.endTime,
    this.venue,
    this.clientName,
    this.clientPhone,
  });

  final String id;
  final String title;
  final DateTime eventDate;
  final String startTime;
  final String? endTime;
  final String? venue;
  final String? clientName;
  final String? clientPhone;
}
