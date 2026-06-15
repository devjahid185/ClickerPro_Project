// lib/features/bookings/data/status_api.dart
//
// Wire-level methods for the booking-scoped status timeline reads.
//
// The status-transition call itself lives on `BookingApi.transitionStatus`.
// This class handles only the append-only fetch path: pulling the
// `status_histories` slice out of the Laravel booking detail payload when
// the UI needs the timeline without re-fetching every nested resource.

import '../../../core/network/api_client.dart';
import '../domain/status_history_entry.dart';
import 'server_wire.dart';

class StatusApi {
  StatusApi(this._client);

  final ApiClient _client;

  /// Returns the append-only status timeline for a booking by hitting
  /// `GET /api/bookings/:id` and slicing the `status_histories` array out
  /// of the Laravel payload. Entries carry the SERVER booking id; callers
  /// that cache them locally must re-point `bookingId` at the local row.
  Future<List<StatusHistoryEntry>> getHistory(String bookingRemoteId) async {
    final r = await _client.get('/api/bookings/$bookingRemoteId');
    final j = unwrapServerMap(r);
    final raw = j['status_histories'] ?? j['statusHistory'] ?? const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => statusEntryFromServer(
            e.cast<String, dynamic>(),
            bookingLocalId: bookingRemoteId,
          ),
        )
        .toList(growable: false);
  }
}
