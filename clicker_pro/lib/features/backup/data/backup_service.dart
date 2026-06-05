// lib/features/backup/data/backup_service.dart
//
// Backup service — exports and imports the Drift database as JSON.
// Auto-backup scheduling is a placeholder for future WorkManager integration.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/backup_record.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const _uuid = Uuid();

  /// Exports the current database to a JSON file and returns a [BackupRecord].
  Future<BackupRecord> exportDatabase({
    required Map<String, dynamic> databaseContent,
    BackupType type = BackupType.manual,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final directory = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${directory.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final fileName = 'backup_${now.millisecondsSinceEpoch}.json';
    final file = File('${backupsDir.path}/$fileName');

    final payload = jsonEncode({
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'data': databaseContent,
    });

    await file.writeAsString(payload);
    final sizeBytes = await file.length();

    return BackupRecord(
      id: id,
      type: type,
      sizeBytes: sizeBytes,
      createdAt: now,
      status: BackupStatus.completed,
      filePath: file.path,
    );
  }

  /// Reads a backup JSON file and returns its data content for restoration.
  Future<Map<String, dynamic>> importDatabase(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Backup file not found', filePath);
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Invalid backup file format — missing "data" key');
    }
    return data;
  }

  /// Returns existing backup files from the backups directory.
  Future<List<BackupRecord>> listBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${directory.path}/backups');
    if (!await backupsDir.exists()) return const [];

    final files =
        backupsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    final records = <BackupRecord>[];
    for (final file in files) {
      final stat = await file.stat();
      records.add(
        BackupRecord(
          id: _uuid.v4(),
          type: BackupType.manual,
          sizeBytes: stat.size,
          createdAt: stat.modified,
          status: BackupStatus.completed,
          filePath: file.path,
        ),
      );
    }
    return records;
  }

  // ── Auto-backup scheduling placeholder ─────────────────────────
  //
  // Future implementation: WorkManager or BackgroundFetch scheduling.
  // scheduleDailyBackup()  — triggers at 02:00 local time
  // scheduleWeeklyBackup() — triggers every Sunday at 03:00 local time
  //
  // Will call exportDatabase() with the appropriate [BackupType].
}
