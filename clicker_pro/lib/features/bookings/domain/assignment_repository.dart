// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import 'assignment.dart';

/// Assignment CRUD scoped to a single booking. Mutations are gated on
/// the `editAssignment` Capability via the supplied [RolePolicy].
abstract class AssignmentRepository {
  /// Live local-first list of all assignments for a booking.
  Stream<List<Assignment>> watchByBooking(String bookingId);

  /// Adds a new assignment. Verifies `editAssignment`.
  Future<void> add(Assignment a, {required RolePolicy policy});

  /// Updates an existing assignment. Verifies `editAssignment`.
  Future<void> update(Assignment a, {required RolePolicy policy});

  /// Removes an assignment by id. Verifies `editAssignment`.
  Future<void> remove(String assignmentId, {required RolePolicy policy});
}
