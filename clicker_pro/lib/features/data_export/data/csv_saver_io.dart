// lib/features/data_export/data/csv_saver_io.dart
//
// Mobile/desktop CSV delivery: write temp files, open the OS share sheet.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_saver.dart';

Future<bool> saveCsvFiles(List<CsvFile> files, {String? subject}) async {
  if (files.isEmpty) return false;

  final dir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final paths = <String>[];

  for (final f in files) {
    final file = File('${dir.path}/${f.name}_$timestamp.csv');
    await file.writeAsString(f.contents);
    paths.add(file.path);
  }

  await SharePlus.instance.share(
    ShareParams(
      files: paths.map(XFile.new).toList(),
      subject: subject,
    ),
  );
  return true;
}
