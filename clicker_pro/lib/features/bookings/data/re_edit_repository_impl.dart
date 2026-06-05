// lib/features/bookings/data/re_edit_repository_impl.dart
//
// Local-first re-edit request repository. `request(...)` gates on
// `Capability.requestReEdit`; `updateStatus(...)` gates on
// `Capability.assignReEdit` OR a self-update path (the assigned editor
// flipping their own status, which is allowed by design).
//
// Status mutations enqueue under the `reEditStatus` entity-type so the
// outbox worker can drain them via the dedicated Tier-C path
// (append-only — never overwrite an existing entry).

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/bookings_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/re_edit_requests_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../domain/re_edit_repository.dart';
import '../domain/re_edit_request.dart';
import '../domain/re_edit_status.dart';
import 're_edit_api.dart';

class ReEditRepositoryImpl implements ReEditRepository {
  ReEditRepositoryImpl({required ReEditApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final ReEditApi _api;
  final AppDatabase _db;

  ReEditRequestsDao get _reEdits => _db.reEditRequestsDao;
  BookingsDao get _bookings => _db.bookingsDao;
  OutboxDao get _outbox => _db.outboxDao;

  ReEditRequest _rowToRequest(ReEditRequestRow r) => ReEditRequest(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    round: r.round,
    editorUserId: r.editorUserId,
    deadline: r.deadline,
    referenceImageUrls: _decodeJsonStringList(r.referenceImageUrlsJson),
    notes: r.notes,
    status: ReEditStatus.values.firstWhere(
      (s) => s.name == r.status,
      orElse: () => ReEditStatus.pending,
    ),
    requestedByUserId: r.requestedByUserId,
    requestedAt: r.requestedAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  ReEditRequestsTableCompanion _modelToCompanion(
    ReEditRequest r, {
    required bool pending,
  }) {
    return ReEditRequestsTableCompanion(
      id: Value(r.id),
      remoteId: Value(r.remoteId),
      bookingId: Value(r.bookingId),
      round: Value(r.round),
      editorUserId: Value(r.editorUserId),
      deadline: Value(r.deadline),
      referenceImageUrlsJson: Value(
        _encodeJsonStringList(r.referenceImageUrls),
      ),
      notes: Value(r.notes),
      status: Value(r.status.name),
      requestedByUserId: Value(r.requestedByUserId),
      requestedAt: Value(r.requestedAt),
      updatedAt: Value(r.updatedAt),
      pending: Value(pending),
    );
  }

  @override
  Stream<List<ReEditRequest>> watchByBooking(String bookingId) {
    return _reEdits
        .watchByBooking(bookingId)
        .map((rows) => rows.map(_rowToRequest).toList(growable: false));
  }

  @override
  Future<int> nextRoundFor(String bookingId) {
    return _reEdits.nextRoundFor(bookingId);
  }

  @override
  Future<ReEditRequest> request({
    required String bookingId,
    required int round,
    required String? editorUserId,
    required DateTime deadline,
    required List<String>? referenceImageUrls,
    required String? notes,
    required String requestedByUserId,
    required RolePolicy policy,
  }) async {
    if (!policy.can(Capability.requestReEdit)) {
      throw RolePolicyDeniedException(
        capability: Capability.requestReEdit,
        role: policy.role,
      );
    }

    final now = DateTime.now();
    final localId = 're-$bookingId-$round-${now.microsecondsSinceEpoch}';
    final entry = ReEditRequest(
      id: localId,
      bookingId: bookingId,
      round: round,
      editorUserId: editorUserId,
      deadline: deadline,
      referenceImageUrls: referenceImageUrls,
      notes: notes,
      status: ReEditStatus.pending,
      requestedByUserId: requestedByUserId,
      requestedAt: now,
      updatedAt: now,
      pending: true,
    );

    await _reEdits.upsert(_modelToCompanion(entry, pending: true));

    try {
      final bookingRow = await _bookings.watchById(bookingId).first;
      final bookingRemoteId = bookingRow?.remoteId;
      if (bookingRemoteId == null) {
        await _outbox.enqueue(
          OutboxTableCompanion.insert(
            entityType: 'reEditRequest',
            entityId: entry.id,
            op: 'create',
            payloadJson: jsonEncode(entry.toJson()),
          ),
        );
        return entry;
      }

      final remote = await _api.create(bookingRemoteId, entry);
      final synced = remote.copyWith(pending: false);
      await _reEdits.upsert(_modelToCompanion(synced, pending: false));
      return synced;
    } catch (e, st) {
      AppLogger.w('reEdit', 'request remote failed; queued in outbox: $e');
      AppLogger.e('reEdit', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'reEditRequest',
          entityId: entry.id,
          op: 'create',
          payloadJson: jsonEncode(entry.toJson()),
        ),
      );
      return entry;
    }
  }

  @override
  Future<void> updateStatus({
    required String reEditId,
    required ReEditStatus toStatus,
    required RolePolicy policy,
    required String currentUserId,
  }) async {
    // Self-update path: the assigned editor can move their own request
    // forward without `assignReEdit`. Otherwise the role must hold the
    // assign capability.
    final existing = await _findById(reEditId);
    final isSelfUpdate =
        existing != null && existing.editorUserId == currentUserId;

    if (!isSelfUpdate && !policy.can(Capability.assignReEdit)) {
      throw RolePolicyDeniedException(
        capability: Capability.assignReEdit,
        role: policy.role,
      );
    }

    if (existing == null) {
      // Nothing to update — surface a state error rather than silently
      // doing nothing.
      throw StateError('ReEditRequest not found: $reEditId');
    }

    final stamped = existing.copyWith(
      status: toStatus,
      updatedAt: DateTime.now(),
      pending: true,
    );
    await _reEdits.upsert(_modelToCompanion(stamped, pending: true));

    try {
      if (existing.remoteId == null) {
        // Parent re-edit hasn't been synced yet; defer.
        await _outbox.enqueue(
          OutboxTableCompanion.insert(
            entityType: 'reEditStatus',
            entityId: reEditId,
            op: 'update',
            payloadJson: jsonEncode({
              'reEditLocalId': reEditId,
              'toStatus': toStatus.name,
            }),
          ),
        );
        return;
      }
      final remote = await _api.updateStatus(existing.remoteId!, toStatus);
      final synced = remote.copyWith(pending: false);
      await _reEdits.upsert(_modelToCompanion(synced, pending: false));
    } catch (e, st) {
      AppLogger.w('reEdit', 'updateStatus failed; queued in outbox: $e');
      AppLogger.e('reEdit', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'reEditStatus',
          entityId: reEditId,
          op: 'update',
          payloadJson: jsonEncode({
            'reEditLocalId': reEditId,
            'reEditRemoteId': existing.remoteId,
            'toStatus': toStatus.name,
          }),
        ),
      );
    }
  }

  /// Walks the request tree to locate a row by id. The DAO exposes
  /// per-booking lists only; in practice the caller passes the bookingId
  /// adjacent to the reEditId so we could narrow this further, but
  /// scanning one booking at a time is plenty fast for the < 50 rows
  /// per booking that re-edits typically reach.
  Future<ReEditRequest?> _findById(String reEditId) async {
    // Without a `getById` on the DAO, walk the active bookings list and
    // check each booking's re-edit list. To avoid an O(N×M) scan on
    // large studios we cap the work by reading every re-edit row via a
    // raw select — the table is small enough that this is cheap.
    final rows = await _db.select(_db.reEditRequestsTable).get();
    for (final r in rows) {
      if (r.id == reEditId) return _rowToRequest(r);
    }
    return null;
  }

  String? _encodeJsonStringList(List<String>? list) {
    if (list == null) return null;
    return jsonEncode(list);
  }

  List<String>? _decodeJsonStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e == null ? '' : e.toString())
            .toList(growable: false);
      }
    } catch (_) {
      // Fall through.
    }
    return null;
  }
}
