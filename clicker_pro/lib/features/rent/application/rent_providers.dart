// lib/features/rent/application/rent_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/rent_api.dart';
import '../data/rent_repository_impl.dart';
import '../domain/rent_record.dart';
import '../domain/rent_repository.dart';

final rentApiProvider = Provider<RentApi>(
  (ref) => RentApi(ref.read(apiClientProvider)),
);

final rentRepositoryProvider = Provider<RentRepository>(
  (ref) => RentRepositoryImpl(api: ref.read(rentApiProvider)),
);

class RentHistoryController extends AsyncNotifier<List<RentRecord>> {
  @override
  Future<List<RentRecord>> build() =>
      ref.read(rentRepositoryProvider).history();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rentRepositoryProvider).history(),
    );
  }

  Future<RentRecord> create(RentRecord draft) async {
    final saved = await ref.read(rentRepositoryProvider).create(draft);
    state.whenData((current) => state = AsyncData([saved, ...current]));
    return saved;
  }

  /// Marks a row RETURNED with the given `actualReturnDate` and updates
  /// the cached list optimistically।  On failure we re-fetch।
  Future<void> markReturned(String id, DateTime actualReturnDate) async {
    final current = state.valueOrNull ?? const <RentRecord>[];
    final idx = current.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final next = [...current];
    next[idx] = RentRecord(
      id: current[idx].id,
      direction: current[idx].direction,
      counterpartyName: current[idx].counterpartyName,
      counterpartyPhone: current[idx].counterpartyPhone,
      amount: current[idx].amount,
      returnBy: current[idx].returnBy,
      actualReturnDate: actualReturnDate,
      status: RentStatus.returned,
      gearItemId: current[idx].gearItemId,
      gearName: current[idx].gearName,
      createdAt: current[idx].createdAt,
    );
    state = AsyncData(next);

    try {
      await ref
          .read(rentRepositoryProvider)
          .updateStatus(
            id: id,
            status: RentStatus.returned,
            actualReturnDate: actualReturnDate,
          );
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

final rentHistoryControllerProvider =
    AsyncNotifierProvider<RentHistoryController, List<RentRecord>>(
      RentHistoryController.new,
    );

/// Derived: number of records that are still ACTIVE (open rentals)।
final activeRentCountProvider = Provider<int>((ref) {
  final async = ref.watch(rentHistoryControllerProvider);
  return async.maybeWhen(
    data: (list) => list.where((r) => r.status == RentStatus.active).length,
    orElse: () => 0,
  );
});
