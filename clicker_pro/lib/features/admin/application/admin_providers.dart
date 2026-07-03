// lib/features/admin/application/admin_providers.dart
//
// Provider tree for the PRO ADMIN app. Reuses the studio app's
// `apiClientProvider` / `authRepositoryProvider` / `sessionControllerProvider`
// unchanged — admin login is the exact same `/api/auth/login` call, just
// gated server-side by role. Only the admin-specific stats/broadcasts data
// layer is new.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/admin_api.dart';
import '../domain/admin_broadcast.dart';
import '../domain/admin_stats.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.read(apiClientProvider)),
);

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) => ref.read(adminApiProvider).stats(),
);

final adminBroadcastsProvider = FutureProvider.autoDispose<List<AdminBroadcast>>(
  (ref) => ref.read(adminApiProvider).broadcasts(),
);
