// lib/features/bookings/data/status_api.dart
//
// Wire-level methods for the booking-scoped status timeline reads.
//
// The status-transition POST itself lives on `BookingApi.transitionStatus`
// because the server returns the cascading `event` row alongside the
// `statusHistoryEntry`. This class handles only the append-only fetch
// path: pulling `statusHistory` out of the booking detail envelope when
// the UI needs the timeline without re-fetching every nested resource.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.6.

import '../../../core/network/api_client.dart';
import '../domain/status_history_entry.dart';

class StatusApi {
  StatusApi(this._client);

  final ApiClient _client;

  /// Returns the append-only status timeline for a booking by hitting
  /// `GET /api/bookings/:id` and slicing the `statusHistory` array out
  /// of the envelope. Other slices of the same envelope (assignments,
  /// payments, etc.) are owned by their dedicated `*Api` classes.
  Future<List<StatusHistoryEntry>> getHistory(String bookingRemoteId) async {
    final r =
        await _client.get('/api/bookings/$bookingRemoteId')
            as Map<String, dynamic>;
    return (r['statusHistory'] as List? ?? const [])
        .map(
          (e) =>
              StatusHistoryEntry.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }
}
