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
      // The studio operates in Bangladesh; pin the local zone so the
      // 1-hour offset is computed against Dhaka wall-clock time.
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Runtime permission (Android 13+ / iOS).
      final android13 = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android13?.requestNotificationsPermission();
      await android13?.requestExactAlarmsPermission();

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
}
