// lib/features/rent/domain/rent_repository.dart

import 'rent_record.dart';

abstract class RentRepository {
  /// `GET /api/rent/history` — owner-scoped descending list with gear info।
  Future<List<RentRecord>> history();

  /// `POST /api/rent/record` — returns the persisted record।
  Future<RentRecord> create(RentRecord draft);

  /// `PATCH /api/rent/status/:id` — RETURNED / OVERDUE।
  /// Pass `actualReturnDate` only when transitioning to RETURNED।
  Future<void> updateStatus({
    required String id,
    required RentStatus status,
    DateTime? actualReturnDate,
  });
}
