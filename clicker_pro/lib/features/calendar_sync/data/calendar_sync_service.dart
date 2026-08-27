import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/calendar_event.dart';

class CalendarSyncService {
  const CalendarSyncService._();

  static Future<void> shareCalendarEvent(CalendarEvent event) async {
    final icsContent = event.toIcsContent();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/graphy7_event.ics');
    await file.writeAsString(icsContent);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: event.title),
    );
  }

  static Future<File> saveIcsFile(CalendarEvent event) async {
    final icsContent = event.toIcsContent();
    final tempDir = await getTemporaryDirectory();
    final safeName = event.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final file = File('${tempDir.path}/$safeName.ics');
    await file.writeAsString(icsContent);
    return file;
  }

  static CalendarEvent bookingToCalendarEvent({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    String venue = '',
    String description = '',
  }) {
    final start = _parseTime(date, startTime);
    final end = _parseTime(date, endTime);

    return CalendarEvent(
      title: title,
      startTime: start,
      endTime: end,
      location: venue,
      description: description,
    );
  }

  static DateTime _parseTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length != 2) return date;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Preference key shared with `CalendarSyncSettings` — when true,
  /// every new booking auto-opens Google Calendar pre-filled.
  static const String autoSyncPrefKey = 'calendar_auto_sync';

  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ON — bookings sync to the device calendar without a manual step.
    return prefs.getBool(autoSyncPrefKey) ?? true;
  }

  /// Builds the Google Calendar "create event" URL pre-filled with the
  /// booking. Opening it adds the event to the signed-in Google account
  /// (the calendar app handles the actual sync).
  static Uri googleCalendarUrl({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? venue,
    String? description,
  }) {
    final start = _parseTime(date, startTime);
    var end = _parseTime(date, endTime);
    if (!end.isAfter(start)) end = start.add(const Duration(hours: 2));
    String two(int v) => v.toString().padLeft(2, '0');
    String fmt(DateTime d) =>
        '${d.year}${two(d.month)}${two(d.day)}T${two(d.hour)}${two(d.minute)}00';

    return Uri.parse('https://calendar.google.com/calendar/render').replace(
      queryParameters: {
        'action': 'TEMPLATE',
        'text': title,
        'dates': '${fmt(start)}/${fmt(end)}',
        if (description != null && description.isNotEmpty)
          'details': description,
        if (venue != null && venue.isNotEmpty) 'location': venue,
      },
    );
  }

  /// Adds the booking to the phone's calendar. First tries a SILENT write
  /// via device_calendar (no Google web page, no manual Save) — if calendar
  /// permission is granted the event just appears.
  ///
  /// [allowWebFallback] controls what happens when the silent write fails:
  ///   • true  → open the pre-filled Google Calendar web page (user taps
  ///             Save there). Used for an explicit user-triggered add.
  ///   • false → give up silently. Used for automatic background sync, where
  ///             yanking the user to a browser to tap "Save" is exactly the
  ///             "manual save" annoyance we want to avoid.
  static Future<bool> openGoogleCalendar({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? venue,
    String? description,
    bool allowWebFallback = true,
    String? bookingId,
  }) async {
    final silent = await _addToDeviceCalendar(
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      venue: venue,
      description: description,
      bookingId: bookingId,
    );
    if (silent || !allowWebFallback) return silent;

    // Fallback: open the pre-filled Google Calendar create page.
    final uri = googleCalendarUrl(
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      venue: venue,
      description: description,
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Writes the event straight into a writable device calendar. Returns
  /// true on success. Fail-soft: any permission / plugin error returns
  /// false so the caller can fall back to the web URL.
  static Future<bool> _addToDeviceCalendar({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? venue,
    String? description,
    String? bookingId,
  }) async {
    try {
      final plugin = DeviceCalendarPlugin();

      // Ensure permission.
      var perm = await plugin.hasPermissions();
      if (perm.isSuccess && perm.data != true) {
        perm = await plugin.requestPermissions();
      }
      if (!(perm.isSuccess && perm.data == true)) return false;

      final calsResult = await plugin.retrieveCalendars();
      final cals = calsResult.data;
      if (cals == null || cals.isEmpty) return false;

      // Prefer a writable Google calendar, then fall back to the default
      // writable calendar on the device.
      final writable = cals.where((c) => c.isReadOnly != true).toList();
      final googleWritable = writable.where((c) {
        final source = [
          c.accountName,
          c.accountType,
          c.name,
        ].whereType<String>().join(' ').toLowerCase();
        return source.contains('google') || source.contains('gmail.com');
      }).toList();
      Calendar target;
      if (googleWritable.isNotEmpty) {
        target = googleWritable.firstWhere(
          (c) => c.isDefault == true,
          orElse: () => googleWritable.first,
        );
      } else {
        target = writable.firstWhere(
          (c) => c.isDefault == true,
          orElse: () => writable.isNotEmpty ? writable.first : cals.first,
        );
      }
      if (target.id == null) return false;

      final start = _parseTime(date, startTime);
      var end = _parseTime(date, endTime);
      if (!end.isAfter(start)) end = start.add(const Duration(hours: 2));
      final marker = bookingId == null ? null : 'GRAPHY7_BOOKING_ID:$bookingId';
      final fullDescription = [
        ?description?.trim(),
        ?marker,
      ].join('\n');

      if (marker != null) {
        final existing = await plugin.retrieveEvents(
          target.id!,
          RetrieveEventsParams(
            startDate: start.subtract(const Duration(hours: 6)),
            endDate: end.add(const Duration(hours: 6)),
          ),
        );
        final alreadyAdded = existing.data?.any((event) =>
                event.description?.contains(marker) == true) ??
            false;
        if (alreadyAdded) {
          AppLogger.i('calendar', 'event already exists silently: ');
          return true;
        }
      }

      // tz.local is set by EventReminderService.init(); guard in case the
      // calendar add runs first.
      tz.TZDateTime tzd(DateTime d) {
        try {
          return tz.TZDateTime.from(d, tz.local);
        } catch (_) {
          return tz.TZDateTime.from(d, tz.UTC);
        }
      }
      final event = Event(
        target.id,
        title: title,
        start: tzd(start),
        end: tzd(end),
        description: fullDescription.isEmpty ? null : fullDescription,
        location: venue,
      );

      final res = await plugin.createOrUpdateEvent(event);
      final ok = res?.isSuccess == true && (res?.data?.isNotEmpty ?? false);
      if (ok) AppLogger.i('calendar', 'event added silently: $title');
      return ok;
    } catch (e) {
      AppLogger.w('calendar', 'silent add failed: $e');
      return false;
    }
  }
}
