import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/reminder_api.dart';
import '../data/reminder_repository_impl.dart';
import '../domain/reminder.dart';

final reminderApiProvider = Provider<ReminderApi>(
  (ref) => ReminderApi(ref.read(apiClientProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepositoryImpl>(
  (ref) => ReminderRepositoryImpl(api: ref.read(reminderApiProvider)),
);

class ReminderListController extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() async {
    return ref.read(reminderRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reminderRepositoryProvider).list(),
    );
  }

  Future<Reminder> add(Reminder draft) async {
    final saved = await ref.read(reminderRepositoryProvider).create(draft);
    state.whenData((current) {
      state = AsyncData(<Reminder>[saved, ...current]);
    });
    return saved;
  }

  Future<void> remove(String id) async {
    await ref.read(reminderRepositoryProvider).delete(id);
    state.whenData((current) {
      state = AsyncData(current.where((r) => r.id != id).toList());
    });
  }
}

final reminderListControllerProvider =
    AsyncNotifierProvider<ReminderListController, List<Reminder>>(
      ReminderListController.new,
    );
