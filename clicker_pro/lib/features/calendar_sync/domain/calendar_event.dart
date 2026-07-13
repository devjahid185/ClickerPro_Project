class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.location = '',
    this.allDay = false,
  });

  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final String location;
  final bool allDay;

  String toIcsContent() {
    final dtStart = _formatIcsDate(startTime, allDay);
    final dtEnd = _formatIcsDate(endTime, allDay);
    final now = _formatIcsDateTime(DateTime.now());

    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Graphy7//Calendar Sync//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('BEGIN:VEVENT')
      ..writeln('DTSTART:$dtStart')
      ..writeln('DTEND:$dtEnd')
      ..writeln('DTSTAMP:$now')
      ..writeln('UID:${_generateUid()}')
      ..writeln('SUMMARY:${_escapeIcs(title)}');
    if (location.isNotEmpty) {
      buf.writeln('LOCATION:${_escapeIcs(location)}');
    }
    if (description.isNotEmpty) {
      buf.writeln('DESCRIPTION:${_escapeIcs(description)}');
    }
    buf
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');
    return buf.toString();
  }

  static String _formatIcsDate(DateTime dt, bool allDay) {
    if (allDay) {
      return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
    }
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}';
  }

  static String _formatIcsDateTime(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _escapeIcs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }

  static String _generateUid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '$now@clickerpro';
  }
}
