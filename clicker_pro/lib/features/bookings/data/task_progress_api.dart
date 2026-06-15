// lib/features/bookings/data/task_progress_api.dart
//
// Per-staff Task Progress endpoints against the Laravel backend. The
// server uses the bearer-token user as the upsert key, so the client
// never supplies a `userId` — the current user is implicit.
//
// Laravel contract (routes/api.php + TaskController):
//   GET  /api/bookings/:eventId/tasks → { data: [row…] }
//   POST /api/bookings/:eventId/tasks → { data: row }
//        body: { percentage, note? }

import '../../../core/network/api_client.dart';
import '../domain/task_progress.dart';
import 'server_wire.dart';

class TaskProgressApi {
  TaskProgressApi(this._client);

  final ApiClient _client;

  TaskProgress _fromServer(
    Map<String, dynamic> j, {
    required String bookingLocalId,
  }) {
    return TaskProgress(
      bookingId: bookingLocalId,
      userId: serverString(j, ['user_id', 'userId']) ?? '',
      percentage:
          int.tryParse((j['percentage'] ?? '0').toString()) ?? 0,
      note: serverString(j, ['note']),
      updatedAt:
          serverDate(j['updated_at'] ?? j['updatedAt']) ?? DateTime.now(),
      pending: false,
    );
  }

  /// Lists a booking's progress rows. [bookingLocalId] is the local
  /// booking row the results should reference.
  Future<List<TaskProgress>> listByBooking(
    String bookingRemoteId, {
    required String bookingLocalId,
  }) async {
    final r = await _client.get('/api/bookings/$bookingRemoteId/tasks');
    return unwrapServerList(r)
        .map((e) => _fromServer(e, bookingLocalId: bookingLocalId))
        .toList(growable: false);
  }

  /// Upserts the current user's progress on a booking.
  Future<TaskProgress> upsert(
    String bookingRemoteId, {
    required int percentage,
    String? note,
    String bookingLocalId = '',
  }) async {
    final r = await _client.post(
      '/api/bookings/$bookingRemoteId/tasks',
      body: {'percentage': percentage, 'note': ?note},
    );
    return _fromServer(
      unwrapServerMap(r),
      bookingLocalId: bookingLocalId.isNotEmpty
          ? bookingLocalId
          : bookingRemoteId,
    );
  }
}
