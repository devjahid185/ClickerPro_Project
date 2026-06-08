// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import 're_edit_request.dart';
import 're_edit_status.dart';

/// ReEditRequest CRUD plus its append-only status transitions.
///
/// All mutations are gated via the supplied [RolePolicy]:
/// - `request(...)` requires `requestReEdit`.
/// - `updateStatus(...)` requires `assignReEdit` (or self-update for the
///   assigned editor — implementations resolve this internally using
///   `currentUserId`).
abstract class ReEditRepository {
  /// Live local-first list of every re-edit request opened against a
  /// booking, ordered by `round` ascending.
  Stream<List<ReEditRequest>> watchByBooking(String bookingId);

  /// Returns the next round number for a booking: `max(round) + 1`, or
  /// `1` when no requests exist yet.
  Future<int> nextRoundFor(String bookingId);

  /// Files a new re-edit request.
  Future<ReEditRequest> request({
    required String bookingId,
    required int round,
    required String? editorUserId,
    required DateTime deadline,
    required List<String>? referenceImageUrls,
    required String? notes,
    required String requestedByUserId,
    required RolePolicy policy,
  });

  /// Returns every re-edit request across all bookings, ordered by deadline.
  Future<List<ReEditRequest>> listAll();

  /// Transitions the status of an existing re-edit request.
  Future<void> updateStatus({
    required String reEditId,
    required ReEditStatus toStatus,
    required RolePolicy policy,
    required String currentUserId,
  });
}
