import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/broadcast_api.dart';
import '../domain/broadcast.dart';

final broadcastApiProvider = Provider<BroadcastApi>(
  (ref) => BroadcastApi(ref.read(apiClientProvider)),
);

/// Active platform broadcasts, newest first. Auto-refreshes when invalidated.
final broadcastsProvider = FutureProvider<List<Broadcast>>(
  (ref) async => ref.read(broadcastApiProvider).list(),
);
