import 'package:drift/drift.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_database.dart';
import '../../expenses/domain/expense_repository.dart';
import '../domain/export_config.dart';
import 'csv_saver.dart';

class ExportService {
  ExportService({
    required AppDatabase db,
    required ExpenseRepository expenseRepo,
  }) : _db = db,
       _expenseRepo = expenseRepo;

  final AppDatabase _db;
  final ExpenseRepository _expenseRepo;

  String generateCsvHeader(List<String> columns) => columns.join(',');

  String generateCsvRow(List<String> values) {
    return values.map(_escapeCsv).join(',');
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<String> exportBookingsCsv(DateRange dateRange) async {
    final rows =
        await (_db.select(_db.bookingsTable)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(dateRange.from) &
                    t.date.isSmallerThanValue(dateRange.to),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();

    final header = generateCsvHeader([
      'ID',
      'Title',
      'Event Type',
      'Date',
      'Start Time',
      'End Time',
      'Shift',
      'Venue',
      'Outdoor',
      'Bride',
      'Groom',
      'Custom Price',
      'Status',
      'Notes',
      'Created At',
    ]);

    final rowsCsv = rows
        .map((r) {
          return generateCsvRow([
            r.id,
            r.title,
            r.eventType,
            r.date.toIso8601String(),
            r.startTime,
            r.endTime,
            r.shift,
            r.venue ?? '',
            r.outdoor.toString(),
            r.brideName ?? '',
            r.groomName ?? '',
            r.customPrice?.toString() ?? '',
            r.status,
            r.notes ?? '',
            r.createdAt.toIso8601String(),
          ]);
        })
        .join('\n');

    return '$header\n$rowsCsv';
  }

  Future<String> exportClientsCsv() async {
    final rows = await (_db.select(
      _db.clientsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

    final header = generateCsvHeader([
      'ID',
      'Name',
      'Phone',
      'Email',
      'Address',
      'DOB',
      'Anniversary',
      'Created At',
    ]);

    final rowsCsv = rows
        .map((r) {
          return generateCsvRow([
            r.id,
            r.name,
            r.phone,
            r.email ?? '',
            r.address ?? '',
            r.dob?.toIso8601String() ?? '',
            r.anniversary?.toIso8601String() ?? '',
            r.createdAt.toIso8601String(),
          ]);
        })
        .join('\n');

    return '$header\n$rowsCsv';
  }

  Future<String> exportPaymentsCsv(DateRange dateRange) async {
    final rows =
        await (_db.select(_db.paymentsTable)
              ..where(
                (t) =>
                    t.createdAt.isBiggerOrEqualValue(dateRange.from) &
                    t.createdAt.isSmallerThanValue(dateRange.to),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    final header = generateCsvHeader([
      'ID',
      'Booking ID',
      'Kind',
      'Amount',
      'Method',
      'Note',
      'Paid At',
      'Created At',
    ]);

    final rowsCsv = rows
        .map((r) {
          return generateCsvRow([
            r.id,
            r.bookingId,
            r.kind,
            r.amount.toString(),
            r.method ?? '',
            r.note ?? '',
            r.paidAt?.toIso8601String() ?? '',
            r.createdAt.toIso8601String(),
          ]);
        })
        .join('\n');

    return '$header\n$rowsCsv';
  }

  Future<String> exportExpensesCsv(DateRange dateRange) async {
    final allExpenses = await _expenseRepo.list();
    final filtered = allExpenses.where((e) {
      return e.incurredAt.isAfter(dateRange.from) &&
          e.incurredAt.isBefore(dateRange.to);
    }).toList();

    final header = generateCsvHeader([
      'ID',
      'Category',
      'Amount',
      'Event ID',
      'Note',
      'Date',
      'Created At',
    ]);

    final rowsCsv = filtered
        .map((e) {
          return generateCsvRow([
            e.id,
            e.category,
            e.amount.toString(),
            e.eventId ?? '',
            e.note ?? '',
            e.incurredAt.toIso8601String(),
            e.createdAt?.toIso8601String() ?? '',
          ]);
        })
        .join('\n');

    return '$header\n$rowsCsv';
  }

  /// Builds every selected scope as an in-memory CSV. Shared by both the
  /// share-sheet export and the Google Sheets export so the two paths never
  /// drift apart.
  Future<List<CsvFile>> _buildCsvFiles(ExportConfig config) async {
    final all = config.scopes.contains(ExportScope.all);
    final files = <CsvFile>[];

    if (all || config.scopes.contains(ExportScope.bookings)) {
      files.add(
        CsvFile(
          name: 'bookings',
          contents: await exportBookingsCsv(config.dateRange),
        ),
      );
    }
    if (all || config.scopes.contains(ExportScope.clients)) {
      files.add(CsvFile(name: 'clients', contents: await exportClientsCsv()));
    }
    if (all || config.scopes.contains(ExportScope.payments)) {
      files.add(
        CsvFile(
          name: 'payments',
          contents: await exportPaymentsCsv(config.dateRange),
        ),
      );
    }
    if (all || config.scopes.contains(ExportScope.expenses)) {
      files.add(
        CsvFile(
          name: 'expenses',
          contents: await exportExpensesCsv(config.dateRange),
        ),
      );
    }
    return files;
  }

  Future<void> shareExport(ExportConfig config) async {
    final files = await _buildCsvFiles(config);
    await deliverCsvFiles(files);
  }

  /// Exports the selected scopes as CSV and hands them to Google Sheets.
  ///
  /// Google's Sheets API needs OAuth + an API key to write a spreadsheet
  /// directly, which we don't ship. The reliable, key-free path Google
  /// itself recommends is: produce a CSV, drop it in Drive, and open it
  /// with Sheets (Sheets imports CSV natively). So we:
  ///   1. write the CSV file(s) to temp,
  ///   2. share them — the Android/iOS share sheet lists **Drive** and
  ///      **Sheets**; picking either lands the data in Google Sheets,
  ///   3. return the file paths so the caller can offer to open Google
  ///      Sheets afterwards for the import step.
  ///
  /// Returns `true` when at least one CSV was delivered.
  Future<bool> exportToGoogleSheets(ExportConfig config) async {
    final files = await _buildCsvFiles(config);
    if (files.isEmpty) return false;
    return deliverCsvFiles(
      files,
      subject: 'Graphy7 export — import into Google Sheets',
    );
  }

  /// Opens Google Sheets so the user can import the CSV they just saved.
  /// Tries the Sheets app first (`https://sheets.google.com`), which the
  /// installed app claims; falls back to the browser. Fail-soft: returns
  /// false if nothing could handle the link.
  Future<bool> openGoogleSheets() async {
    final uri = Uri.parse('https://docs.google.com/spreadsheets/u/0/');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<int> countBookings(DateRange dateRange) async {
    final rows =
        await (_db.select(_db.bookingsTable)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(dateRange.from) &
                  t.date.isSmallerThanValue(dateRange.to),
            ))
            .get();
    return rows.length;
  }

  Future<int> countClients() async {
    final rows = await _db.select(_db.clientsTable).get();
    return rows.length;
  }

  Future<int> countPayments(DateRange dateRange) async {
    final rows =
        await (_db.select(_db.paymentsTable)..where(
              (t) =>
                  t.createdAt.isBiggerOrEqualValue(dateRange.from) &
                  t.createdAt.isSmallerThanValue(dateRange.to),
            ))
            .get();
    return rows.length;
  }

  Future<int> countExpenses(DateRange dateRange) async {
    final allExpenses = await _expenseRepo.list();
    return allExpenses.where((e) {
      return e.incurredAt.isAfter(dateRange.from) &&
          e.incurredAt.isBefore(dateRange.to);
    }).length;
  }
}
