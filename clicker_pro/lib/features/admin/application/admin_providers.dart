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
import '../domain/admin_ticket.dart';
import '../domain/admin_user.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.read(apiClientProvider)),
);

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) => ref.read(adminApiProvider).stats(),
);

final adminBroadcastsProvider = FutureProvider.autoDispose<List<AdminBroadcast>>(
  (ref) => ref.read(adminApiProvider).broadcasts(),
);

/// `role` is null for "Total Users" (no filter). For roles that can also be
/// held jointly (`OWNER`/`FREELANCER` vs. combined `'BOTH'`), the provider
/// fetches both the exact role and `'BOTH'` and merges the results so e.g.
/// "Studio Owners" also includes users who are `BOTH`.
final adminUsersProvider = FutureProvider.autoDispose
    .family<List<AdminUser>, String?>((ref, role) async {
  final api = ref.read(adminApiProvider);
  if (role == null || role == 'ADMIN') {
    return api.users(role: role);
  }
  if (role == 'OWNER' || role == 'FREELANCER') {
    final results = await Future.wait([
      api.users(role: role),
      api.users(role: 'BOTH'),
    ]);
    final seen = <String>{};
    return [
      for (final list in results)
        for (final u in list)
          if (seen.add(u.id)) u,
    ];
  }
  return api.users(role: role);
});

final adminTicketsProvider = FutureProvider.autoDispose<List<AdminTicket>>(
  (ref) => ref.read(adminApiProvider).tickets(),
);

/// Current OTA update channel values (versionCode/versionName/apkUrl/
/// forceUpdate/releaseNotes) — what every studio app compares itself against
/// on launch. Kept as a raw map: the shape is owned by AppVersionController.
final adminAppVersionProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(adminApiProvider).appVersion(),
);
