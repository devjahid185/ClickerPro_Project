import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/app_database.dart';
import '../../expenses/domain/expense_repository.dart';
import '../domain/export_config.dart';

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

  Future<void> shareExport(ExportConfig config) async {
    final dir = await getTemporaryDirectory();
    final files = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (config.scopes.contains(ExportScope.bookings) ||
        config.scopes.contains(ExportScope.all)) {
      final csv = await exportBookingsCsv(config.dateRange);
      final file = File('${dir.path}/bookings_$timestamp.csv');
      await file.writeAsString(csv);
      files.add(file.path);
    }

    if (config.scopes.contains(ExportScope.clients) ||
        config.scopes.contains(ExportScope.all)) {
      final csv = await exportClientsCsv();
      final file = File('${dir.path}/clients_$timestamp.csv');
      await file.writeAsString(csv);
      files.add(file.path);
    }

    if (config.scopes.contains(ExportScope.payments) ||
        config.scopes.contains(ExportScope.all)) {
      final csv = await exportPaymentsCsv(config.dateRange);
      final file = File('${dir.path}/payments_$timestamp.csv');
      await file.writeAsString(csv);
      files.add(file.path);
    }

    if (config.scopes.contains(ExportScope.expenses) ||
        config.scopes.contains(ExportScope.all)) {
      final csv = await exportExpensesCsv(config.dateRange);
      final file = File('${dir.path}/expenses_$timestamp.csv');
      await file.writeAsString(csv);
      files.add(file.path);
    }

    if (files.isEmpty) return;

    if (files.length == 1) {
      await SharePlus.instance.share(ShareParams(files: [XFile(files.first)]));
    } else {
      await SharePlus.instance.share(
        ShareParams(files: files.map(XFile.new).toList()),
      );
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
