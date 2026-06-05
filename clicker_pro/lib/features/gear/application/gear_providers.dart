// lib/features/gear/application/gear_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/gear_api.dart';
import '../data/gear_repository_impl.dart';
import '../domain/gear_item.dart';
import '../domain/gear_repository.dart';

final gearApiProvider = Provider<GearApi>(
  (ref) => GearApi(ref.read(apiClientProvider)),
);

final gearRepositoryProvider = Provider<GearRepository>(
  (ref) => GearRepositoryImpl(api: ref.read(gearApiProvider)),
);

class GearListController extends AsyncNotifier<List<GearItem>> {
  @override
  Future<List<GearItem>> build() => ref.read(gearRepositoryProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gearRepositoryProvider).list(),
    );
  }

  Future<GearItem> add(GearItem draft) async {
    final saved = await ref.read(gearRepositoryProvider).add(draft);
    state.whenData((current) => state = AsyncData([saved, ...current]));
    return saved;
  }

  Future<void> remove(String id) async {
    await ref.read(gearRepositoryProvider).remove(id);
    state.whenData(
      (current) => state = AsyncData(
        current.where((g) => g.id != id).toList(growable: false),
      ),
    );
  }
}

final gearListControllerProvider =
    AsyncNotifierProvider<GearListController, List<GearItem>>(
      GearListController.new,
    );

/// Total kit value — derived from the live list.  Surfaces in the
/// header card so studio operators see the kit valuation at a glance।
final totalGearValueProvider = Provider<double>((ref) {
  final async = ref.watch(gearListControllerProvider);
  return async.maybeWhen(
    data: (items) => items.fold<double>(0, (s, g) => s + g.value),
    orElse: () => 0,
  );
});
