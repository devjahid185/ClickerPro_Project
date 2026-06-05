// lib/features/freelancer/data/fl_tools_repository_impl.dart
//
// Online-first repository implementation for the freelancer work-tools
// feature (FL-05–FL-09). Delegates every call to [FlToolsApi].
//
// Failure mode: any network/auth error bubbles up as ApiException —
// the UI tier catches and surfaces in a SnackBar / inline error state.

import '../domain/fl_blackout_date.dart';
import '../domain/fl_checkin.dart';
import '../domain/fl_leave_request.dart';
import '../domain/fl_tools_repository.dart';
import 'fl_tools_api.dart';

class FlToolsRepositoryImpl implements FlToolsRepository {
  FlToolsRepositoryImpl({required FlToolsApi api}) : _api = api;

  final FlToolsApi _api;

  // ─── Blackout Dates (FL-05) ─────────────────────────────────────

  @override
  Future<List<FlBlackoutDate>> listBlackouts() => _api.listBlackouts();

  @override
  Future<FlBlackoutDate> createBlackout(FlBlackoutDate draft) =>
      _api.createBlackout(draft);

  @override
  Future<void> deleteBlackout(String id) => _api.deleteBlackout(id);

  // ─── Work History (FL-06) ───────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listWorkHistory() =>
      _api.listWorkHistory();

  // ─── Leave Requests (FL-07) ─────────────────────────────────────

  @override
  Future<List<FlLeaveRequest>> listLeaveRequests() => _api.listLeaveRequests();

  @override
  Future<FlLeaveRequest> createLeaveRequest(FlLeaveRequest draft) =>
      _api.createLeaveRequest(draft);

  @override
  Future<FlLeaveRequest> cancelLeaveRequest(String id) =>
      _api.cancelLeaveRequest(id);

  // ─── Multi-Owner Dashboard (FL-08) ──────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listAllOwnerEvents() =>
      _api.listAllOwnerEvents();

  @override
  Future<List<Map<String, dynamic>>> listConflicts() => _api.listConflicts();

  // ─── Live Check-In (FL-09) ──────────────────────────────────────

  @override
  Future<FlCheckin> recordCheckin(FlCheckin draft) => _api.recordCheckin(draft);

  @override
  Future<FlCheckin?> getCheckinStatus(String eventId) =>
      _api.getCheckinStatus(eventId);
}
