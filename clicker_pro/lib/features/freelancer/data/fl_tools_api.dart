// lib/features/freelancer/data/fl_tools_api.dart
//
// Wire-level methods for the freelancer work-tools endpoints (FL-05–FL-09).
// Mirrors planned backend routes:
//
//   Blackout dates:
//     GET    /api/freelancer/blackouts       → list
//     POST   /api/freelancer/blackouts       → create
//     DELETE /api/freelancer/blackouts/:id    → remove
//
//   Work history:
//     GET    /api/freelancer/work-history     → list past events
//
//   Leave requests:
//     GET    /api/freelancer/leaves           → list
//     POST   /api/freelancer/leaves           → create
//     PATCH  /api/freelancer/leaves/:id       → update (cancel)
//
//   Multi-owner dashboard:
//     GET    /api/freelancer/dashboard/events → all events across owners
//     GET    /api/freelancer/dashboard/conflicts → overlap warnings
//
//   Check-in:
//     POST   /api/freelancer/checkin          → record check-in
//     GET    /api/freelancer/checkin/:eventId → status for event
//
// All endpoints require the `Bearer <jwt>` header — supplied by
// `ApiClient` automatically.

import '../../../core/network/api_client.dart';
import '../domain/fl_blackout_date.dart';
import '../domain/fl_checkin.dart';
import '../domain/fl_leave_request.dart';

class FlToolsApi {
  FlToolsApi(this._client);

  final ApiClient _client;

  // ─── Blackout Dates (FL-05) ─────────────────────────────────────

  Future<List<FlBlackoutDate>> listBlackouts() async {
    final r =
        await _client.get('/api/freelancer/blackouts') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(FlBlackoutDate.fromJson)
        .toList(growable: false);
  }

  Future<FlBlackoutDate> createBlackout(FlBlackoutDate draft) async {
    final r =
        await _client.post('/api/freelancer/blackouts', body: draft.toJson())
            as Map<String, dynamic>;
    final created = (r['data'] as Map).cast<String, dynamic>();
    return FlBlackoutDate.fromJson(created);
  }

  Future<void> deleteBlackout(String id) async {
    await _client.delete('/api/freelancer/blackouts/$id');
  }

  // ─── Work History (FL-06) ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> listWorkHistory() async {
    final r =
        await _client.get('/api/freelancer/work-history')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw.cast<Map<String, dynamic>>().toList(growable: false);
  }

  // ─── Leave Requests (FL-07) ─────────────────────────────────────

  Future<List<FlLeaveRequest>> listLeaveRequests() async {
    final r =
        await _client.get('/api/freelancer/leaves') as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(FlLeaveRequest.fromJson)
        .toList(growable: false);
  }

  Future<FlLeaveRequest> createLeaveRequest(FlLeaveRequest draft) async {
    final r =
        await _client.post('/api/freelancer/leaves', body: draft.toJson())
            as Map<String, dynamic>;
    final created = (r['data'] as Map).cast<String, dynamic>();
    return FlLeaveRequest.fromJson(created);
  }

  Future<FlLeaveRequest> cancelLeaveRequest(String id) async {
    final r =
        await _client.patch(
              '/api/freelancer/leaves/$id',
              body: {'status': 'cancelled'},
            )
            as Map<String, dynamic>;
    final updated = (r['data'] as Map).cast<String, dynamic>();
    return FlLeaveRequest.fromJson(updated);
  }

  // ─── Multi-Owner Dashboard (FL-08) ──────────────────────────────

  Future<List<Map<String, dynamic>>> listAllOwnerEvents() async {
    final r =
        await _client.get('/api/freelancer/dashboard/events')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw.cast<Map<String, dynamic>>().toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> listConflicts() async {
    final r =
        await _client.get('/api/freelancer/dashboard/conflicts')
            as Map<String, dynamic>;
    final raw = (r['data'] as List?) ?? const <dynamic>[];
    return raw.cast<Map<String, dynamic>>().toList(growable: false);
  }

  // ─── Live Check-In (FL-09) ──────────────────────────────────────

  Future<FlCheckin> recordCheckin(FlCheckin draft) async {
    final r =
        await _client.post('/api/freelancer/checkin', body: draft.toJson())
            as Map<String, dynamic>;
    final created = (r['data'] as Map).cast<String, dynamic>();
    return FlCheckin.fromJson(created);
  }

  Future<FlCheckin?> getCheckinStatus(String eventId) async {
    final r =
        await _client.get('/api/freelancer/checkin/$eventId')
            as Map<String, dynamic>;
    final data = r['data'];
    if (data == null) return null;
    return FlCheckin.fromJson((data as Map).cast<String, dynamic>());
  }
}
