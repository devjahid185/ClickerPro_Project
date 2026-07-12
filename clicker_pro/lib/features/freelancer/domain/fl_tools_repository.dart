// lib/features/freelancer/domain/fl_tools_repository.dart
//
// Abstract contract for the freelancer work-tools feature (FL-05–FL-09).
// Implementation lives in `data/fl_tools_repository_impl.dart`.

import 'fl_blackout_date.dart';
import 'fl_checkin.dart';

abstract class FlToolsRepository {
  // ─── Blackout Dates (FL-05) ─────────────────────────────────────

  Future<List<FlBlackoutDate>> listBlackouts();
  Future<FlBlackoutDate> createBlackout(FlBlackoutDate draft);
  Future<void> deleteBlackout(String id);

  // ─── Work History (FL-06) ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> listWorkHistory();

  // ─── Multi-Owner Dashboard (FL-08) ──────────────────────────────

  Future<List<Map<String, dynamic>>> listAllOwnerEvents();
  Future<List<Map<String, dynamic>>> listConflicts();

  // ─── Live Check-In (FL-09) ──────────────────────────────────────

  Future<FlCheckin> recordCheckin(FlCheckin draft);
  Future<FlCheckin?> getCheckinStatus(String eventId);
}
