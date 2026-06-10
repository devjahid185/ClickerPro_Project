// lib/features/bookings/data/booking_api.dart
//
// Wire-level methods for the Booking (Event) endpoints against the
// Laravel backend. All request/response shape translation (the
// `{data}` envelope, snake_case columns, integer ids, SCREAMING_SNAKE
// enums) is delegated to `server_wire.dart` so this class stays thin.
//
// Laravel contract (routes/api.php + BookingController):
//   GET    /api/bookings              → { data: [event…] }
//   POST   /api/bookings              → { data: event } (201)
//   GET    /api/bookings/:id          → { data: event+relations }
//   PATCH  /api/bookings/:id          → { data: event }
//   PATCH  /api/bookings/:id/status   → { data: event }   body {status, note}
//   DELETE /api/bookings/:id          → { message: ok }

import 'dart:convert';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/booking.dart';
import '../domain/booking_detail_envelope.dart';
import '../domain/booking_filter.dart';
import '../domain/status_history_entry.dart';
import 'booking_api_exceptions.dart';
import 'server_wire.dart';

class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  /// `GET /api/bookings` — role-scoped list.
  ///
  /// The Laravel endpoint returns the full (optionally status/search
  /// filtered) set under `data`; paging values are echoed locally since
  /// the server does not paginate this endpoint yet.
  Future<({List<Booking> items, int page, int total})> list(
    BookingFilter filter, {
    int page = 0,
    int pageSize = 20,
  }) async {
    final r = await _client.get(
      '/api/bookings',
      query: _filterToQuery(filter),
    );
    final items = unwrapServerList(r)
        .map((e) => bookingFromServer(e))
        .toList(growable: false);
    return (items: items, page: page, total: items.length);
  }

  /// `GET /api/bookings/:id` — detail envelope.
  ///
  /// The Laravel payload nests `client`, `status_histories`, `payments`,
  /// `assignments`, `package` inside the event row. Booking + client +
  /// status timeline are mapped; the remaining slices are owned by their
  /// own feature modules and are filled from the local cache by the
  /// repository, so they are returned empty here.
  Future<BookingDetailEnvelope> get(String remoteId) async {
    final r = await _client.get('/api/bookings/$remoteId');
    final j = unwrapServerMap(r);

    final booking = bookingFromServer(j);

    final clientRaw = j['client'];
    final client = clientRaw is Map
        ? clientFromServer(clientRaw.cast<String, dynamic>())
        : null;

    final historyRaw =
        j['status_histories'] ?? j['statusHistory'] ?? j['statusHistories'];
    final history = historyRaw is List
        ? historyRaw
              .whereType<Map>()
              .map(
                (e) => statusEntryFromServer(
                  e.cast<String, dynamic>(),
                  bookingLocalId: booking.id,
                ),
              )
              .toList(growable: false)
        : const <StatusHistoryEntry>[];

    return BookingDetailEnvelope(
      booking: booking,
      client: client,
      assignments: const [],
      payments: const [],
      package: null,
      statusHistory: history,
      reEditRequests: const [],
      taskProgress: const [],
    );
  }

  /// `POST /api/bookings` — create. The response is mapped with the
  /// submitted booking as fallback so the LOCAL id (and every field the
  /// server does not persist) survives the round-trip — only `remoteId`
  /// and the server-authoritative fields are adopted.
  Future<Booking> create(Booking booking) async {
    final r = await _client.post(
      '/api/bookings',
      body: bookingToServer(booking),
    );
    return bookingFromServer(unwrapServerMap(r), fallback: booking);
  }

  /// `PATCH /api/bookings/:id` — partial update. [partial] is the full
  /// local `Booking.toJson()` map (both call sites pass exactly that),
  /// re-parsed here and translated to the server's snake_case body.
  Future<Booking> patch(String remoteId, Map<String, dynamic> partial) async {
    final local = Booking.fromJson(partial);
    final r = await _client.patch(
      '/api/bookings/$remoteId',
      body: bookingToServer(local),
    );
    return bookingFromServer(unwrapServerMap(r), fallback: local);
  }

  /// `DELETE /api/bookings/:id`.
  Future<void> delete(String remoteId) async {
    await _client.delete('/api/bookings/$remoteId');
  }

  /// `PATCH /api/bookings/:id/status` — transition the lifecycle status.
  ///
  /// Laravel takes `{status, note}` and appends the StatusHistory row
  /// server-side; the response carries only the updated event. The
  /// timeline entry is synthesized locally from the requested transition
  /// so callers keep receiving the `(event, entry)` pair.
  ///
  /// On HTTP 409 the server reports its own current status; this method
  /// re-throws as a typed [StatusConflictException] carrying the parsed
  /// `serverStatus` so the repository can adopt the server value and
  /// drop the local pending statusHistory row.
  Future<({Booking event, StatusHistoryEntry entry})> transitionStatus({
    required String remoteId,
    required BookingStatus from,
    required BookingStatus to,
    String? note,
  }) async {
    try {
      final r = await _client.patch(
        '/api/bookings/$remoteId/status',
        body: {'status': bookingStatusToServer(to), 'note': ?note},
      );
      final j = unwrapServerMap(r);
      final event = bookingFromServer(j);
      final entry = StatusHistoryEntry(
        id: 'sh_${DateTime.now().microsecondsSinceEpoch}',
        bookingId: event.id,
        fromStatus: from,
        toStatus: to,
        changedByUserId: '',
        note: note,
        at: DateTime.now(),
        pending: false,
      );
      return (event: event, entry: entry);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw StatusConflictException(
          serverStatus: _parseServerStatus(e.body),
          message: e.message,
        );
      }
      rethrow;
    }
  }

  /// Builds the query map used by [list]. The Laravel index endpoint
  /// understands `status` (single value), `search`, and `limit`; a status
  /// filter is forwarded only when exactly one status is selected (multi-
  /// status filtering happens locally against the Drift cache).
  Map<String, dynamic> _filterToQuery(BookingFilter filter) {
    final query = <String, dynamic>{};
    if (filter.statuses.length == 1) {
      query['status'] = bookingStatusToServer(filter.statuses.first);
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      query['search'] = filter.search;
    }
    return query;
  }

  /// Pulls `serverStatus` out of the 409 body. The body is the raw
  /// response string captured by `ApiClient`; we decode lazily so a
  /// non-JSON or missing field falls back to [BookingStatus.pending]
  /// rather than failing the whole transition pipeline.
  BookingStatus _parseServerStatus(String? body) {
    if (body == null || body.isEmpty) return BookingStatus.pending;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final raw = decoded['serverStatus'] ?? decoded['currentStatus'];
        if (raw != null) return bookingStatusFromServer(raw);
      }
    } catch (_) {
      // Fall through to default.
    }
    return BookingStatus.pending;
  }
}
