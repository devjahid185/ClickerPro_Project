// lib/features/admin/data/admin_api.dart
//
// Wire client for the PRO ADMIN app. Every endpoint here lives behind
// Laravel's `auth:sanctum` + `admin` middleware (routes/api.php, prefix
// `admin/`) — the SAME Sanctum token the studio app already uses to log in,
// gated server-side on `role === 'ADMIN'`. No separate admin auth exists;
// `AuthApi.login` (reused as-is) issues a valid token for an admin account
// exactly like it does for a studio owner.

import '../../../core/network/api_client.dart';
import '../domain/admin_broadcast.dart';
import '../domain/admin_setting.dart';
import '../domain/admin_stats.dart';
import '../domain/admin_ticket.dart';
import '../domain/admin_user.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _map(dynamic r) {
    if (r is Map) {
      final d = r['data'];
      if (d is Map) return d.cast<String, dynamic>();
      return r.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic r) {
    if (r is Map) {
      final d = r['data'];
      if (d is List) {
        return d
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false);
      }
    }
    return const [];
  }

  Future<AdminStats> stats() async {
    final r = await _client.get('/api/admin/stats');
    return AdminStats.fromJson(_map(r));
  }

  /// Uploads an image via the shared `/api/files/upload` endpoint (the same
  /// one the studio app uses for logos/avatars) and returns its public URL,
  /// ready to pass as `imageUrl` to [createBroadcast] / [updateBroadcast].
  Future<String> uploadImage(String filePath) async {
    final r = await _client.postMultipart(
      '/api/files/upload',
      filePath: filePath,
      field: 'file',
    );
    final url = _map(r)['url'];
    if (url is! String || url.isEmpty) {
      throw StateError('Upload succeeded but returned no url');
    }
    return url;
  }

  Future<List<AdminBroadcast>> broadcasts() async {
    final r = await _client.get('/api/admin/broadcasts');
    return _list(r).map(AdminBroadcast.fromJson).toList(growable: false);
  }

  Future<AdminBroadcast> createBroadcast({
    required String title,
    required String body,
    String? targetRole,
    bool isActive = true,
    String? priority,
    String? type,
    String? link,
    String? buttonLabel,
    String? imageUrl,
    int? timesPerDay,
  }) async {
    final r = await _client.post(
      '/api/admin/broadcasts',
      body: {
        'title': title,
        'body': body,
        'target_role': ?targetRole,
        'is_active': isActive,
        'priority': ?priority,
        'type': ?type,
        'link': ?link,
        'button_label': ?buttonLabel,
        'image_url': ?imageUrl,
        'times_per_day': ?timesPerDay,
      },
    );
    return AdminBroadcast.fromJson(_map(r));
  }

  Future<AdminBroadcast> updateBroadcast(
    String id, {
    String? title,
    String? body,
    String? targetRole,
    bool? isActive,
    String? priority,
    String? type,
    String? link,
    String? buttonLabel,
    String? imageUrl,
    int? timesPerDay,
  }) async {
    final r = await _client.patch(
      '/api/admin/broadcasts/$id',
      body: {
        'title': ?title,
        'body': ?body,
        'target_role': ?targetRole,
        'is_active': ?isActive,
        'priority': ?priority,
        'type': ?type,
        'link': ?link,
        'button_label': ?buttonLabel,
        'image_url': ?imageUrl,
        'times_per_day': ?timesPerDay,
      },
    );
    return AdminBroadcast.fromJson(_map(r));
  }

  Future<void> deleteBroadcast(String id) async {
    await _client.delete('/api/admin/broadcasts/$id');
  }

  /// [role] filters server-side (e.g. `'OWNER'`, `'FREELANCER'`, `'ADMIN'`).
  /// Owners/freelancers who also hold the other role are stored as `'BOTH'`
  /// and won't match a single-role filter — callers that need "all owners"
  /// should also query `'BOTH'` and merge/dedupe if that distinction matters.
  Future<List<AdminUser>> users({String? role}) async {
    final r = await _client.get(
      '/api/admin/users',
      query: role == null ? null : {'role': role},
    );
    return _list(r).map(AdminUser.fromJson).toList(growable: false);
  }

  Future<List<AdminTicket>> tickets() async {
    final r = await _client.get('/api/admin/tickets');
    return _list(r).map(AdminTicket.fromJson).toList(growable: false);
  }

  Future<void> replyToTicket(String id, {required String reply, String status = 'CLOSED'}) async {
    await _client.patch(
      '/api/admin/tickets/$id',
      body: {'admin_reply': reply, 'status': status},
    );
  }

  // ── Per-user admin actions (AdminController::setRole/setPlan/setSuspend) ──

  Future<void> setUserRole(String id, String role) async {
    await _client.patch('/api/admin/users/$id/role', body: {'role': role});
  }

  Future<void> setUserPlan(String id, String plan) async {
    await _client.patch('/api/admin/users/$id/plan', body: {'plan': plan});
  }

  Future<void> setUserSuspended(String id, bool suspended) async {
    await _client.patch(
      '/api/admin/users/$id/suspend',
      body: {'suspended': suspended},
    );
  }

  // ── OTA app-version channel (AppVersionController) ──
  // GET is public (the studio app polls it on launch); PATCH is admin-only.

  Future<Map<String, dynamic>> appVersion() async {
    final r = await _client.get('/api/app/version');
    return _map(r);
  }

  Future<Map<String, dynamic>> updateAppVersion({
    int? versionCode,
    String? versionName,
    String? apkUrl,
    bool? forceUpdate,
    String? releaseNotes,
  }) async {
    final r = await _client.patch(
      '/api/admin/app/version',
      body: {
        'versionCode': ?versionCode,
        'versionName': ?versionName,
        'apkUrl': ?apkUrl,
        'forceUpdate': ?forceUpdate,
        'releaseNotes': ?releaseNotes,
      },
    );
    return _map(r);
  }

  // ── AppSetting key/value store (SettingsController) ──
  // The landing page (LandingController) renders every text from these keys,
  // so saving here changes the live site on the next page load.

  /// Grouped by key prefix: `{"landing": [...], "app": [...], ...}`.
  Future<Map<String, List<AdminSetting>>> settings() async {
    final r = await _client.get('/api/admin/settings');
    final data = _map(r);
    return {
      for (final entry in data.entries)
        if (entry.value is List)
          entry.key: (entry.value as List)
              .whereType<Map>()
              .map((e) => AdminSetting.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false),
    };
  }

  Future<void> updateSettings(Map<String, String> changes) async {
    await _client.post('/api/admin/settings', body: {'settings': changes});
  }
}
