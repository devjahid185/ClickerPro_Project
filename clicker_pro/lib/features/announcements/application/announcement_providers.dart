import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/announcement_api.dart';
import '../data/announcement_repository_impl.dart';
import '../domain/announcement.dart';
import '../domain/announcement_repository.dart';

final announcementApiProvider = Provider<AnnouncementApi>(
  (ref) => AnnouncementApi(ref.read(apiClientProvider)),
);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(api: ref.read(announcementApiProvider)),
);

class AnnouncementListController extends AsyncNotifier<List<Announcement>> {
  @override
  Future<List<Announcement>> build() =>
      ref.read(announcementRepositoryProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(announcementRepositoryProvider).list(),
    );
  }

  Future<Announcement> create(Announcement draft) async {
    final saved = await ref.read(announcementRepositoryProvider).create(draft);
    state.whenData((current) => state = AsyncData([saved, ...current]));
    return saved;
  }

  Future<void> togglePin(String id, bool currentPinned) async {
    await ref.read(announcementRepositoryProvider).update(id, {
      'pinned': !currentPinned,
    });
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(announcementRepositoryProvider).remove(id);
    state.whenData(
      (current) => state = AsyncData(
        current.where((a) => a.id != id).toList(growable: false),
      ),
    );
  }

  Future<void> markRead(String id) async {
    await ref.read(announcementRepositoryProvider).markRead(id);
    await refresh();
  }
}

final announcementListControllerProvider =
    AsyncNotifierProvider<AnnouncementListController, List<Announcement>>(
      AnnouncementListController.new,
    );

/// Sorted list: pinned first, then by createdAt descending.
final sortedAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((
  ref,
) {
  final async = ref.watch(announcementListControllerProvider);
  return async.whenData((items) {
    final sorted = List<Announcement>.from(items)
      ..sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted;
  });
});
