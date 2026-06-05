// lib/features/gear/domain/gear_repository.dart

import 'gear_item.dart';

abstract class GearRepository {
  /// `GET /api/gear/my-gear` — owner-scoped descending list।
  Future<List<GearItem>> list();

  /// `POST /api/gear/add` — returns the persisted record (with id)।
  Future<GearItem> add(GearItem draft);

  /// `DELETE /api/gear/:id` — owner-scoped; backend 403s on cross-tenant।
  Future<void> remove(String id);
}
