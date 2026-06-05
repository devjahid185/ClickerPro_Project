// lib/features/bookings/data/re_edit_api.dart
//
// Wire-level methods for the Re-edit Request endpoints. Wraps `ApiClient`
// calls and returns plain `ReEditRequest` domain instances.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.12.

import '../../../core/network/api_client.dart';
import '../domain/re_edit_request.dart';
import '../domain/re_edit_status.dart';

class ReEditApi {
  ReEditApi(this._client);

  final ApiClient _client;

  /// `GET /api/bookings/:id/reedits`.
  Future<List<ReEditRequest>> listByBooking(String bookingRemoteId) async {
    final r =
        await _client.get('/api/bookings/$bookingRemoteId/reedits')
            as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map((e) => ReEditRequest.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/bookings/:id/reedits`.
  Future<ReEditRequest> create(
    String bookingRemoteId,
    ReEditRequest request,
  ) async {
    final r =
        await _client.post(
              '/api/bookings/$bookingRemoteId/reedits',
              body: request.toJson(),
            )
            as Map<String, dynamic>;
    return ReEditRequest.fromJson(
      (r['reEditRequest'] as Map).cast<String, dynamic>(),
    );
  }

  /// `PATCH /api/reedits/:reEditId/status`.
  Future<ReEditRequest> updateStatus(
    String reEditRemoteId,
    ReEditStatus toStatus,
  ) async {
    final r =
        await _client.patch(
              '/api/reedits/$reEditRemoteId/status',
              body: {'toStatus': toStatus.name},
            )
            as Map<String, dynamic>;
    return ReEditRequest.fromJson(
      (r['reEditRequest'] as Map).cast<String, dynamic>(),
    );
  }
}
