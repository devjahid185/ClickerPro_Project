// lib/features/bookings/data/assignment_api.dart
//
// Wire-level methods for booking-scoped Assignment endpoints against the
// Laravel backend. Shape translation lives in `server_wire.dart`.
//
// Laravel contract (routes/api.php + AssignmentController):
//   GET    /api/bookings/:eventId/assignments        → { data: [row…] }
//   POST   /api/bookings/:eventId/assignments        → { data: row } (201)
//   PATCH  /api/bookings/:eventId/assignments/:id    → { data: row }
//   DELETE /api/bookings/:eventId/assignments/:id    → { message: ok }

import '../../../core/network/api_client.dart';
import '../domain/assignment.dart';
import 'server_wire.dart';

class AssignmentApi {
  AssignmentApi(this._client);

  final ApiClient _client;

  /// Creates an assignment against the booking's SERVER id. The response
  /// is mapped with the submitted assignment as fallback so the LOCAL ids
  /// survive the round-trip.
  Future<Assignment> create(
    String bookingRemoteId,
    Assignment assignment,
  ) async {
    final r = await _client.post(
      '/api/bookings/$bookingRemoteId/assignments',
      body: assignmentToServer(assignment),
    );
    return assignmentFromServer(
      unwrapServerMap(r),
      bookingLocalId: assignment.bookingId,
      fallback: assignment,
    );
  }

  /// Lists a booking's assignments. [bookingLocalId] is the local row the
  /// returned assignments should reference.
  Future<List<Assignment>> list(
    String bookingRemoteId, {
    required String bookingLocalId,
  }) async {
    final r = await _client.get('/api/bookings/$bookingRemoteId/assignments');
    return unwrapServerList(r)
        .map((e) => assignmentFromServer(e, bookingLocalId: bookingLocalId))
        .toList(growable: false);
  }

  /// Partial update. [partial] is the full local `Assignment.toJson()`
  /// map (both call sites pass exactly that).
  Future<Assignment> patch(
    String bookingRemoteId,
    String assignmentRemoteId,
    Map<String, dynamic> partial,
  ) async {
    final local = Assignment.fromJson(partial);
    final r = await _client.patch(
      '/api/bookings/$bookingRemoteId/assignments/$assignmentRemoteId',
      body: assignmentToServer(local),
    );
    return assignmentFromServer(
      unwrapServerMap(r),
      bookingLocalId: local.bookingId,
      fallback: local,
    );
  }

  /// `DELETE /api/bookings/:id/assignments/:assignmentId`.
  Future<void> delete(String bookingRemoteId, String assignmentRemoteId) async {
    await _client.delete(
      '/api/bookings/$bookingRemoteId/assignments/$assignmentRemoteId',
    );
  }
}
