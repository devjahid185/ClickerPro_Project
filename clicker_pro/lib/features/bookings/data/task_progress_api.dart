// lib/features/bookings/data/task_progress_api.dart
//
// Wire-level methods for the per-staff Task Progress endpoints. Server
// uses the bearer-token user as the upsert key, so the visitor side never
// supplies a `userId` — the current user is implicit.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" section. Validates Requirement 13.13.

import '../../../core/network/api_client.dart';
import '../domain/task_progress.dart';

class TaskProgressApi {
  TaskProgressApi(this._client);

  final ApiClient _client;

  /// `GET /api/bookings/:id/task-progress`.
  Future<List<TaskProgress>> listByBooking(String bookingRemoteId) async {
    final r =
        await _client.get('/api/bookings/$bookingRemoteId/task-progress')
            as Map<String, dynamic>;
    return (r['items'] as List? ?? const [])
        .map((e) => TaskProgress.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/bookings/:id/task-progress` — upsert keyed by the bearer
  /// token's user id (the server reads it off the request, the client
  /// never sends a `userId` here).
  Future<TaskProgress> upsert(
    String bookingRemoteId, {
    required int percentage,
    String? note,
  }) async {
    final r =
        await _client.post(
              '/api/bookings/$bookingRemoteId/task-progress',
              body: {'percentage': percentage, 'note': ?note},
            )
            as Map<String, dynamic>;
    return TaskProgress.fromJson(
      (r['taskProgress'] as Map).cast<String, dynamic>(),
    );
  }
}
