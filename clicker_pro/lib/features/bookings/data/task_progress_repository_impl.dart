// lib/features/bookings/data/task_progress_repository_impl.dart
//
// Local-first task-progress repository keyed by `(bookingId, userId)`.
// `upsert(...)` gates on `Capability.updateTaskProgress` (Property 11).
// For Freelancer roles the implementation additionally enforces
// `userId == currentUserId` AND that an assignment exists for the given
// booking — the design specifies this is enforced internally rather than
// via a dedicated capability.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/assignments_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/task_progress_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../../auth/domain/user_role.dart';
import '../domain/task_progress.dart';
import '../domain/task_progress_repository.dart';
import 'task_progress_api.dart';

class TaskProgressRepositoryImpl implements TaskProgressRepository {
  TaskProgressRepositoryImpl({
    required TaskProgressApi api,
    required AppDatabase db,
    required String currentUserId,
  }) : _api = api,
       _db = db,
       _currentUserId = currentUserId;

  final TaskProgressApi _api;
  final AppDatabase _db;
  final String _currentUserId;

  TaskProgressDao get _taskProgress => _db.taskProgressDao;
  AssignmentsDao get _assignments => _db.assignmentsDao;
  OutboxDao get _outbox => _db.outboxDao;

  TaskProgress _rowToProgress(TaskProgressRow r) => TaskProgress(
    bookingId: r.bookingId,
    userId: r.userId,
    percentage: r.percentage,
    note: r.note,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  TaskProgressTableCompanion _modelToCompanion(
    TaskProgress t, {
    required bool pending,
  }) {
    return TaskProgressTableCompanion(
      bookingId: Value(t.bookingId),
      userId: Value(t.userId),
      percentage: Value(t.percentage),
      note: Value(t.note),
      updatedAt: Value(t.updatedAt),
      pending: Value(pending),
    );
  }

  @override
  Stream<List<TaskProgress>> watchByBooking(String bookingId) {
    return _taskProgress
        .watchByBooking(bookingId)
        .map((rows) => rows.map(_rowToProgress).toList(growable: false));
  }

  @override
  Stream<TaskProgress?> watchOwn({
    required String bookingId,
    required String userId,
  }) {
    return _taskProgress
        .watchOwn(bookingId: bookingId, userId: userId)
        .map((r) => r == null ? null : _rowToProgress(r));
  }

  @override
  Future<void> upsert({
    required String bookingId,
    required String userId,
    required int percentage,
    required String? note,
    required RolePolicy policy,
  }) async {
    if (!policy.can(Capability.updateTaskProgress)) {
      throw RolePolicyDeniedException(
        capability: Capability.updateTaskProgress,
        role: policy.role,
      );
    }

    // Freelancer: only their own row, only when an assignment exists.
    if (policy.role == UserRole.freelancer) {
      if (userId != _currentUserId) {
        throw RolePolicyDeniedException(
          capability: Capability.updateTaskProgress,
          role: policy.role,
          message: 'Freelancers can only update their own task progress row.',
        );
      }
      final assignments = await _assignments.watchByBooking(bookingId).first;
      final hasAssignment = assignments.any((a) => a.userId == userId);
      if (!hasAssignment) {
        throw RolePolicyDeniedException(
          capability: Capability.updateTaskProgress,
          role: policy.role,
          message:
              'Freelancers must be assigned to the booking to post progress.',
        );
      }
    }

    final entry = TaskProgress(
      bookingId: bookingId,
      userId: userId,
      percentage: percentage,
      note: note,
      updatedAt: DateTime.now(),
      pending: true,
    );

    await _taskProgress.upsert(_modelToCompanion(entry, pending: true));

    try {
      // Server uses the bearer-token user as the upsert key — we only
      // forward the percentage + note. We POST when the actor IS the
      // current user; for owner/manager rows targeting a different
      // userId the local-first path stands and the outbox carries the
      // payload with both ids so the worker can issue the right call.
      if (userId == _currentUserId) {
        // We need the booking's remoteId to call the API; if it's not
        // yet synced, defer.
        // The DAO doesn't expose `getById` for booking from this
        // repository's wiring; we go through Drift directly.
        final bookingRow = await (_db.select(
          _db.bookingsTable,
        )..where((t) => t.id.equals(bookingId))).getSingleOrNull();
        final bookingRemoteId = bookingRow?.remoteId;
        if (bookingRemoteId == null) {
          await _outbox.enqueue(
            OutboxTableCompanion.insert(
              entityType: 'taskProgress',
              entityId: '$bookingId/$userId',
              op: 'update',
              payloadJson: jsonEncode(entry.toJson()),
            ),
          );
          return;
        }

        final remote = await _api.upsert(
          bookingRemoteId,
          percentage: percentage,
          note: note,
        );
        final synced = remote.copyWith(pending: false);
        await _taskProgress.upsert(_modelToCompanion(synced, pending: false));
      } else {
        // Owner/manager updating someone else's row: the bearer-token
        // server endpoint won't accept a foreign userId, so leave this
        // path as a queued outbox item (the worker uses an admin
        // endpoint when one is added). For now the local row stands
        // and the queued payload carries the foreign userId.
        await _outbox.enqueue(
          OutboxTableCompanion.insert(
            entityType: 'taskProgress',
            entityId: '$bookingId/$userId',
            op: 'update',
            payloadJson: jsonEncode(entry.toJson()),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.w('taskProgress', 'upsert failed; queued in outbox: $e');
      AppLogger.e('taskProgress', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'taskProgress',
          entityId: '$bookingId/$userId',
          op: 'update',
          payloadJson: jsonEncode(entry.toJson()),
        ),
      );
    }
  }
}
