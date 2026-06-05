// lib/features/bookings/data/assignment_api.dart
//
// Wire-level methods for booking-scoped Assignment endpoints (CRUD per
// booking). Wraps `ApiClient` calls and returns plain `Assignment`
// domain instances.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.9.

import '../../../core/network/api_client.dart';
import '../domain/assignment.dart';

class AssignmentApi {
  AssignmentApi(this._client);

  final ApiClient _client;

  /// `POST /api/bookings/:id/assignments`.
  Future<Assignment> create(
    String bookingRemoteId,
    Assignment assignment,
  ) async {
    final r =
        await _client.post(
              '/api/bookings/$bookingRemoteId/assignments',
              body: assignment.toJson(),
            )
            as Map<String, dynamic>;
    return Assignment.fromJson(
      (r['assignment'] as Map).cast<String, dynamic>(),
    );
  }

  /// `PATCH /api/bookings/:id/assignments/:assignmentId`.
  Future<Assignment> patch(
    String bookingRemoteId,
    String assignmentRemoteId,
    Map<String, dynamic> partial,
  ) async {
    final r =
        await _client.patch(
              '/api/bookings/$bookingRemoteId/assignments/$assignmentRemoteId',
              body: partial,
            )
            as Map<String, dynamic>;
    return Assignment.fromJson(
      (r['assignment'] as Map).cast<String, dynamic>(),
    );
  }

  /// `DELETE /api/bookings/:id/assignments/:assignmentId`.
  Future<void> delete(String bookingRemoteId, String assignmentRemoteId) async {
    await _client.delete(
      '/api/bookings/$bookingRemoteId/assignments/$assignmentRemoteId',
    );
  }
}
