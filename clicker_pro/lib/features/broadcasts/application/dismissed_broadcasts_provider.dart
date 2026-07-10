import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/kv_store.dart';

/// Tracks which platform broadcasts the user has dismissed with the banner's
/// (×) close button, so a closed broadcast stays gone across app restarts.
///
/// Persisted as a JSON string array under [KvKeys.seenBroadcastIds]. The set
/// is loaded once on first read and kept in memory; [dismiss] appends and
/// writes through so the next launch already knows.
class DismissedBroadcastsNotifier extends StateNotifier<Set<String>> {
  DismissedBroadcastsNotifier() : super(const {}) {
    _load();
  }

  final KvStore _kv = KvStore();

  Future<void> _load() async {
    try {
      final raw = await _kv.readString(KvKeys.seenBroadcastIds) ?? '';
      if (raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      // Corrupt / missing store — start from an empty set.
    }
  }

  /// Marks [id] dismissed and persists the updated set. No-op for a blank id
  /// or one already dismissed.
  Future<void> dismiss(String id) async {
    if (id.isEmpty || state.contains(id)) return;
    final next = {...state, id};
    state = next;
    try {
      await _kv.writeString(KvKeys.seenBroadcastIds, jsonEncode(next.toList()));
    } catch (_) {
      // Persist failed — the in-memory dismissal still hides it this session.
    }
  }
}

final dismissedBroadcastsProvider =
    StateNotifierProvider<DismissedBroadcastsNotifier, Set<String>>(
  (ref) => DismissedBroadcastsNotifier(),
);
