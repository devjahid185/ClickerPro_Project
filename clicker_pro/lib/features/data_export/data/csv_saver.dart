// lib/features/data_export/data/csv_saver.dart
//
// Platform-adaptive CSV delivery. The mobile build writes temp files and
// hands them to the OS share sheet (Drive / Sheets / WhatsApp …). The web
// build cannot touch `dart:io` or `path_provider` — calling them threw and
// left the export silently doing nothing (Heaven: "Data export সিলেক্ট করা
// যায় কিন্তু এক্সপোর্ট করা যায় না"). On web each CSV is streamed straight to a
// browser download instead.
//
// The correct implementation is picked at compile time via conditional
// import: `csv_saver_io.dart` on mobile/desktop, `csv_saver_web.dart` on web.

import 'csv_saver_stub.dart'
    if (dart.library.io) 'csv_saver_io.dart'
    if (dart.library.js_interop) 'csv_saver_web.dart';

/// One CSV file to deliver: a base name (no extension) and its contents.
class CsvFile {
  const CsvFile({required this.name, required this.contents});
  final String name;
  final String contents;
}

/// Delivers [files] to the user in the most native way for the platform.
///
/// - Mobile/desktop: writes temp `.csv` files and opens the share sheet,
///   optionally with [subject].
/// - Web: triggers a browser download for each file.
///
/// Returns `true` when at least one file was delivered.
Future<bool> deliverCsvFiles(List<CsvFile> files, {String? subject}) =>
    saveCsvFiles(files, subject: subject);
