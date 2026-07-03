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
import '../domain/admin_stats.dart';

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
        return d.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
      }
    }
    return const [];
  }

  Future<AdminStats> stats() async {
    final r = await _client.get('/api/admin/stats');
    return AdminStats.fromJson(_map(r));
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
    int? timesPerDay,
  }) async {
    final r = await _client.post(
      '/api/admin/broadcasts',
      body: {
        'title': title,
        'body': body,
        if (targetRole != null) 'target_role': targetRole,
        'is_active': isActive,
        if (priority != null) 'priority': priority,
        if (type != null) 'type': type,
        if (link != null) 'link': link,
        if (buttonLabel != null) 'button_label': buttonLabel,
        if (timesPerDay != null) 'times_per_day': timesPerDay,
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
    int? timesPerDay,
  }) async {
    final r = await _client.patch(
      '/api/admin/broadcasts/$id',
      body: {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (targetRole != null) 'target_role': targetRole,
        if (isActive != null) 'is_active': isActive,
        if (priority != null) 'priority': priority,
        if (type != null) 'type': type,
        if (link != null) 'link': link,
        if (buttonLabel != null) 'button_label': buttonLabel,
        if (timesPerDay != null) 'times_per_day': timesPerDay,
      },
    );
    return AdminBroadcast.fromJson(_map(r));
  }

  Future<void> deleteBroadcast(String id) async {
    await _client.delete('/api/admin/broadcasts/$id');
  }
}
