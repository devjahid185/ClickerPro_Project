// lib/features/data_export/data/csv_saver_stub.dart
//
// Fallback used only when neither dart:io nor dart:js_interop is available.
// Never actually reached on a real Flutter target, but required so the
// conditional import in csv_saver.dart type-checks everywhere.

import 'csv_saver.dart';

Future<bool> saveCsvFiles(List<CsvFile> files, {String? subject}) async {
  throw UnsupportedError('CSV export is not supported on this platform.');
}
