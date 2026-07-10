import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../data/export_service.dart';
import '../domain/export_config.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    db: ref.read(appDatabaseProvider),
    expenseRepo: ref.read(expenseRepositoryProvider),
  );
});

enum DateRangePreset { any, today, thisWeek, thisMonth, custom }

class ExportControllerState {
  final ExportType type;
  final Set<ExportScope> scopes;
  final DateRangePreset dateRangePreset;
  final DateRange dateRange;
  final bool generating;
  final Map<ExportScope, int> itemCounts;

  ExportControllerState({
    this.type = ExportType.csv,
    this.scopes = const {ExportScope.bookings},
    this.dateRangePreset = DateRangePreset.any,
    required this.dateRange,
    this.generating = false,
    this.itemCounts = const {},
  });

  ExportControllerState copyWith({
    ExportType? type,
    Set<ExportScope>? scopes,
    DateRangePreset? dateRangePreset,
    DateRange? dateRange,
    bool? generating,
    Map<ExportScope, int>? itemCounts,
  }) {
    return ExportControllerState(
      type: type ?? this.type,
      scopes: scopes ?? this.scopes,
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
      dateRange: dateRange ?? this.dateRange,
      generating: generating ?? this.generating,
      itemCounts: itemCounts ?? this.itemCounts,
    );
  }
}

class ExportController extends Notifier<ExportControllerState> {
  @override
  ExportControllerState build() =>
      ExportControllerState(dateRange: DateRange.all());

  void setType(ExportType type) {
    state = state.copyWith(type: type);
  }

  void toggleScope(ExportScope scope) {
    final current = Set<ExportScope>.from(state.scopes);
    if (current.contains(scope)) {
      current.remove(scope);
    } else {
      current.add(scope);
    }
    state = state.copyWith(scopes: current);
    refreshCounts();
  }

  void selectAllScopes() {
    state = state.copyWith(
      scopes: {
        ExportScope.bookings,
        ExportScope.clients,
        ExportScope.payments,
        ExportScope.expenses,
      },
    );
    refreshCounts();
  }

  void clearScopes() {
    state = state.copyWith(scopes: {});
  }

  void setDateRangePreset(DateRangePreset preset) {
    DateRange range;
    switch (preset) {
      case DateRangePreset.any:
        range = DateRange.all();
        break;
      case DateRangePreset.today:
        range = DateRange.today();
        break;
      case DateRangePreset.thisWeek:
        range = DateRange.thisWeek();
        break;
      case DateRangePreset.thisMonth:
        range = DateRange.thisMonth();
        break;
      case DateRangePreset.custom:
        range = state.dateRange;
        break;
    }
    state = state.copyWith(dateRangePreset: preset, dateRange: range);
    refreshCounts();
  }

  void setCustomDateRange(DateRange range) {
    state = state.copyWith(
      dateRangePreset: DateRangePreset.custom,
      dateRange: range,
    );
    refreshCounts();
  }

  Future<void> refreshCounts() async {
    final service = ref.read(exportServiceProvider);
    final range = state.dateRange;
    final counts = <ExportScope, int>{};

    for (final scope in state.scopes) {
      switch (scope) {
        case ExportScope.bookings:
          counts[scope] = await service.countBookings(range);
          break;
        case ExportScope.clients:
          counts[scope] = await service.countClients();
          break;
        case ExportScope.payments:
          counts[scope] = await service.countPayments(range);
          break;
        case ExportScope.expenses:
          counts[scope] = await service.countExpenses(range);
          break;
        case ExportScope.all:
          break;
      }
    }
    state = state.copyWith(itemCounts: counts);
  }

  /// Runs the export. Returns `true` when a Google Sheets export produced
  /// files (so the screen can offer to open Sheets for the import step);
  /// `false` for every other format. Never throws to the caller — errors
  /// are swallowed so the button always resets.
  Future<bool> generateAndShare() async {
    state = state.copyWith(generating: true);
    try {
      final service = ref.read(exportServiceProvider);
      final config = ExportConfig(
        type: state.type,
        scopes: state.scopes,
        dateRange: state.dateRange,
      );
      if (state.type == ExportType.googleSheets) {
        final files = await service.exportToGoogleSheets(config);
        return files.isNotEmpty;
      }
      await service.shareExport(config);
      return false;
    } finally {
      state = state.copyWith(generating: false);
    }
  }

  /// Opens Google Sheets so the user can import the CSV they just shared.
  Future<bool> openGoogleSheets() =>
      ref.read(exportServiceProvider).openGoogleSheets();
}

final exportControllerProvider =
    NotifierProvider<ExportController, ExportControllerState>(
      ExportController.new,
    );
