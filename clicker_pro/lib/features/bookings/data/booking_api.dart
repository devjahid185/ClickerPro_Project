// lib/features/bookings/data/booking_api.dart
//
// Wire-level methods for the Booking (Event) endpoints. Wraps `ApiClient`
// calls, parses the JSON via `Booking.fromJson` / `BookingDetailEnvelope`,
// and re-throws structured exceptions (`StatusConflictException` on 409
// from the status-transition path).
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirements 13.1–13.6.

import 'dart:convert';

import '../../../core/booking_status/booking_status.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/booking.dart';
import '../domain/booking_detail_envelope.dart';
import '../domain/booking_filter.dart';
import '../domain/event_type.dart';
import '../domain/status_history_entry.dart';
import 'booking_api_exceptions.dart';

class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  /// `GET /api/bookings` — paginated, role-scoped, filter-aware.
  Future<({List<Booking> items, int page, int total})> list(
    BookingFilter filter, {
    int page = 0,
    int pageSize = 20,
  }) async {
    final query = _filterToQuery(filter, page, pageSize);
    final r =
        await _client.get('/api/bookings', query: query)
            as Map<String, dynamic>;
    final items = (r['items'] as List? ?? const [])
        .map((e) => Booking.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return (
      items: items,
      page: (r['page'] as num?)?.toInt() ?? page,
      total: (r['total'] as num?)?.toInt() ?? items.length,
    );
  }

  /// `GET /api/bookings/:id` — full detail envelope (booking + client +
  /// assignments + payments + package + statusHistory + reEditRequests +
  /// taskProgress).
  Future<BookingDetailEnvelope> get(String remoteId) async {
    final r =
        await _client.get('/api/bookings/$remoteId') as Map<String, dynamic>;
    return BookingDetailEnvelope.fromJson(r);
  }

  /// `POST /api/bookings` — create.
  Future<Booking> create(Booking booking) async {
    final r =
        await _client.post('/api/bookings', body: booking.toJson())
            as Map<String, dynamic>;
    return Booking.fromJson((r['event'] as Map).cast<String, dynamic>());
  }

  /// `PATCH /api/bookings/:id` — partial update.
  Future<Booking> patch(String remoteId, Map<String, dynamic> partial) async {
    final r =
        await _client.patch('/api/bookings/$remoteId', body: partial)
            as Map<String, dynamic>;
    return Booking.fromJson((r['event'] as Map).cast<String, dynamic>());
  }

  /// `DELETE /api/bookings/:id`.
  Future<void> delete(String remoteId) async {
    await _client.delete('/api/bookings/$remoteId');
  }

  /// `POST /api/bookings/:id/status` — append a transition.
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
      final r =
          await _client.post(
                '/api/bookings/$remoteId/status',
                body: {
                  'fromStatus': from.name,
                  'toStatus': to.name,
                  'note': ?note,
                },
              )
              as Map<String, dynamic>;
      return (
        event: Booking.fromJson((r['event'] as Map).cast<String, dynamic>()),
        entry: StatusHistoryEntry.fromJson(
          (r['statusHistoryEntry'] as Map).cast<String, dynamic>(),
        ),
      );
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

  /// Builds the query map used by [list] from a [BookingFilter] +
  /// pagination cursor. Repeated values (`status[]`, `type[]`) are
  /// joined with commas — the `ApiClient` URL builder serializes any
  /// non-`null` value via `toString`, so we hand it pre-joined strings.
  Map<String, dynamic> _filterToQuery(
    BookingFilter filter,
    int page,
    int pageSize,
  ) {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'sort': filter.sort.name,
    };
    if (filter.from != null) {
      query['from'] = filter.from!.toIso8601String();
    }
    if (filter.to != null) {
      query['to'] = filter.to!.toIso8601String();
    }
    if (filter.statuses.isNotEmpty) {
      query['status'] = _joinNames<BookingStatus>(filter.statuses);
    }
    if (filter.types.isNotEmpty) {
      query['type'] = _joinNames<EventType>(filter.types);
    }
    if (filter.clientId != null) {
      query['clientId'] = filter.clientId;
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      query['search'] = filter.search;
    }
    return query;
  }

  String _joinNames<T extends Enum>(Set<T> values) =>
      values.map((v) => v.name).join(',');

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
        if (raw is String) {
          for (final s in BookingStatus.values) {
            if (s.name == raw) return s;
          }
        }
      }
    } catch (_) {
      // Fall through to default.
    }
    return BookingStatus.pending;
  }
}
