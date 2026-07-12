// lib/features/data_export/data/csv_saver_web.dart
//
// Web CSV delivery: stream each CSV straight to a browser download. There is
// no filesystem or OS share sheet on the web, so `dart:io` + path_provider
// (the mobile path) throw here — which is exactly why export "did nothing" on
// the web app. We build a Blob and click a synthetic <a download> link.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'csv_saver.dart';

Future<bool> saveCsvFiles(List<CsvFile> files, {String? subject}) async {
  if (files.isEmpty) return false;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  for (final f in files) {
    final blob = web.Blob(
      [f.contents.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement
          ..href = url
          ..download = '${f.name}_$timestamp.csv'
          ..style.display = 'none';
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
  return true;
}
