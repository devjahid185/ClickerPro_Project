// lib/features/bookings/data/assignment_repository_impl.dart
//
// Local-first assignment repository scoped to a single booking.
// Mutations gate on `Capability.editAssignment` (Property 11) and use the
// same upsert + outbox pattern as `UserRepositoryImpl`.
//
// Network calls require the parent booking's `remoteId`; if the booking
// has not yet been synced, the assignment write is queued in the outbox
// and the worker drains it once the booking acquires a `remoteId`.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/assignments_dao.dart';
import '../../../core/db/daos/bookings_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../domain/assignment.dart';
import '../domain/assignment_repository.dart';
import '../domain/assignment_role.dart';
import 'assignment_api.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  AssignmentRepositoryImpl({
    required AssignmentApi api,
    required AppDatabase db,
  }) : _api = api,
       _db = db;

  final AssignmentApi _api;
  final AppDatabase _db;

  AssignmentsDao get _assignments => _db.assignmentsDao;
  BookingsDao get _bookings => _db.bookingsDao;
  OutboxDao get _outbox => _db.outboxDao;

  Assignment _rowToAssignment(AssignmentRow r) => Assignment(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    userId: r.userId,
    role: AssignmentRole.values.firstWhere(
      (x) => x.name == r.role,
      orElse: () => AssignmentRole.assistant,
    ),
    payout: r.payout,
    notes: r.notes,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  AssignmentsTableCompanion _modelToCompanion(
    Assignment a, {
    required bool pending,
  }) {
    return AssignmentsTableCompanion(
      id: Value(a.id),
      remoteId: Value(a.remoteId),
      bookingId: Value(a.bookingId),
      userId: Value(a.userId),
      role: Value(a.role.name),
      payout: Value(a.payout),
      notes: Value(a.notes),
      createdAt: Value(a.createdAt),
      updatedAt: Value(a.updatedAt),
      pending: Value(pending),
    );
  }

  void _verify(RolePolicy policy) {
    if (!policy.can(Capability.editAssignment)) {
      throw RolePolicyDeniedException(
        capability: Capability.editAssignment,
        role: policy.role,
      );
    }
  }

  @override
  Stream<List<Assignment>> watchByBooking(String bookingId) {
    return _assignments
        .watchByBooking(bookingId)
        .map((rows) => rows.map(_rowToAssignment).toList(growable: false));
  }

  @override
  Future<void> add(Assignment a, {required RolePolicy policy}) async {
    _verify(policy);
    await _persist(a, op: 'create');
  }

  @override
  Future<void> update(Assignment a, {required RolePolicy policy}) async {
    _verify(policy);
    await _persist(a, op: 'update');
  }

  @override
  Future<void> remove(String assignmentId, {required RolePolicy policy}) async {
    _verify(policy);

    // Drift hard-delete first; the local row vanishes from any active
    // `watchByBooking` stream so the UI updates instantly. The outbox
    // worker handles the matching server-side DELETE asynchronously.
    await _assignments.deleteById(assignmentId);

    await _outbox.enqueue(
      OutboxTableCompanion.insert(
        entityType: 'assignment',
        entityId: assignmentId,
        op: 'delete',
        payloadJson: jsonEncode({'id': assignmentId}),
      ),
    );
  }

  Future<void> _persist(Assignment a, {required String op}) async {
    final stamped = a.copyWith(updatedAt: DateTime.now(), pending: true);
    await _assignments.upsert(_modelToCompanion(stamped, pending: true));

    try {
      final bookingRow = await _bookings.watchById(stamped.bookingId).first;
      final bookingRemoteId = bookingRow?.remoteId;
      if (bookingRemoteId == null) {
        // Parent booking is still pending sync. Defer the API call to
        // the outbox; the worker will retry once the booking has a
        // remoteId.
        await _outbox.enqueue(
          OutboxTableCompanion.insert(
            entityType: 'assignment',
            entityId: stamped.id,
            op: op,
            payloadJson: jsonEncode(stamped.toJson()),
          ),
        );
        return;
      }

      final remote = op == 'create'
          ? await _api.create(bookingRemoteId, stamped)
          : await _api.patch(
              bookingRemoteId,
              stamped.remoteId ?? stamped.id,
              stamped.toJson(),
            );
      final synced = remote.copyWith(pending: false);
      await _assignments.upsert(_modelToCompanion(synced, pending: false));
    } catch (e, st) {
      AppLogger.w('assignment', '$op remote failed; queued in outbox: $e');
      AppLogger.e('assignment', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'assignment',
          entityId: stamped.id,
          op: op,
          payloadJson: jsonEncode(stamped.toJson()),
        ),
      );
    }
  }
}
