// lib/features/bookings/data/re_edit_api.dart
//
// Re-edit Request endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + ReEditController):
//   GET   /api/bookings/:eventId/reedits → { data: [row…] }
//   POST  /api/bookings/:eventId/reedits → { data: row } (201)
//         body: { description }
//   PATCH /api/reedits/:id               → { data: row }
//         body: { status: PENDING|APPROVED|REJECTED, admin_note? }
//
// The server schema is leaner than the local model (no rounds, deadlines,
// editor or reference images) — those fields stay device-local; the
// description carries the user-entered notes.

import '../../../core/network/api_client.dart';
import '../domain/re_edit_request.dart';
import '../domain/re_edit_status.dart';
import 'server_wire.dart';

class ReEditApi {
  ReEditApi(this._client);

  final ApiClient _client;

  ReEditStatus _statusFromServer(Object? raw, {ReEditStatus? fallback}) {
    switch ((raw ?? '').toString().toUpperCase()) {
      case 'APPROVED':
        return ReEditStatus.inProgress;
      case 'REJECTED':
        return ReEditStatus.rejected;
      case 'PENDING':
        return ReEditStatus.pending;
      default:
        return fallback ?? ReEditStatus.pending;
    }
  }

  String _statusToServer(ReEditStatus s) {
    switch (s) {
      case ReEditStatus.pending:
        return 'PENDING';
      case ReEditStatus.inProgress:
      case ReEditStatus.done:
        return 'APPROVED';
      case ReEditStatus.rejected:
        return 'REJECTED';
    }
  }

  ReEditRequest _fromServer(
    Map<String, dynamic> j, {
    required String bookingLocalId,
    ReEditRequest? fallback,
  }) {
    final serverId = serverString(j, ['id']);
    return ReEditRequest(
      id: fallback?.id ?? serverId ?? '',
      remoteId: serverId ?? fallback?.remoteId,
      bookingId: bookingLocalId,
      round: fallback?.round ?? 1,
      editorUserId: fallback?.editorUserId,
      deadline:
          fallback?.deadline ?? DateTime.now().add(const Duration(days: 7)),
      referenceImageUrls: fallback?.referenceImageUrls,
      notes: serverString(j, ['description']) ?? fallback?.notes,
      status: _statusFromServer(j['status'], fallback: fallback?.status),
      requestedByUserId:
          serverString(j, ['requested_by']) ??
          fallback?.requestedByUserId ??
          '',
      requestedAt:
          serverDate(j['created_at']) ??
          fallback?.requestedAt ??
          DateTime.now(),
      updatedAt:
          serverDate(j['updated_at']) ?? fallback?.updatedAt ?? DateTime.now(),
      pending: false,
    );
  }

  /// Lists a booking's re-edit requests. [bookingLocalId] is the local
  /// booking row the results should reference.
  Future<List<ReEditRequest>> listByBooking(
    String bookingRemoteId, {
    required String bookingLocalId,
  }) async {
    final r = await _client.get('/api/bookings/$bookingRemoteId/reedits');
    return unwrapServerList(r)
        .map((e) => _fromServer(e, bookingLocalId: bookingLocalId))
        .toList(growable: false);
  }

  /// `POST /api/bookings/:id/reedits`.
  Future<ReEditRequest> create(
    String bookingRemoteId,
    ReEditRequest request,
  ) async {
    final description = (request.notes?.trim().isNotEmpty ?? false)
        ? request.notes!.trim()
        : 'Re-edit request (round ${request.round})';
    final r = await _client.post(
      '/api/bookings/$bookingRemoteId/reedits',
      body: {'description': description},
    );
    return _fromServer(
      unwrapServerMap(r),
      bookingLocalId: request.bookingId,
      fallback: request,
    );
  }

  /// `PATCH /api/reedits/:id`.
  Future<ReEditRequest> updateStatus(
    String reEditRemoteId,
    ReEditStatus toStatus,
  ) async {
    final r = await _client.patch(
      '/api/reedits/$reEditRemoteId',
      body: {'status': _statusToServer(toStatus)},
    );
    final j = unwrapServerMap(r);
    return _fromServer(
      j,
      bookingLocalId: serverString(j, ['event_id']) ?? '',
    ).copyWith(status: toStatus);
  }
}
