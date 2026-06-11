import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/calendar_event.dart';

class CalendarSyncService {
  const CalendarSyncService._();

  static Future<void> shareCalendarEvent(CalendarEvent event) async {
    final icsContent = event.toIcsContent();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/clicker_event.ics');
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
    return prefs.getBool(autoSyncPrefKey) ?? false;
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

  /// Opens Google Calendar pre-filled for [title]/[date]. Returns false
  /// when the URL could not be launched (no handler / blocked).
  static Future<bool> openGoogleCalendar({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? venue,
    String? description,
  }) {
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
}
