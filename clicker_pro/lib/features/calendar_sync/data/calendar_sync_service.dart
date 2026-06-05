import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
}
