// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import 'task_progress.dart';

/// TaskProgress upsert keyed by `(bookingId, userId)`.
///
/// Owners/Both/Manager can upsert any user's row; Freelancer is
/// restricted by the implementation to `userId == currentUserId` AND the
/// existence of an assignment for the given booking. The Capability gate
/// (`updateTaskProgress`) is verified via the supplied [RolePolicy].
abstract class TaskProgressRepository {
  /// Live local-first list of every per-staff progress row for a
  /// booking.
  Stream<List<TaskProgress>> watchByBooking(String bookingId);

  /// Live local-first own-row stream for the dashboard "my tasks"
  /// section. Emits `null` until the row is first inserted.
  Stream<TaskProgress?> watchOwn({
    required String bookingId,
    required String userId,
  });

  /// Upsert keyed by `(bookingId, userId)`.
  Future<void> upsert({
    required String bookingId,
    required String userId,
    required int percentage,
    required String? note,
    required RolePolicy policy,
  });
}
