// lib/features/gear/data/gear_repository_impl.dart

import '../domain/gear_item.dart';
import '../domain/gear_repository.dart';
import 'gear_api.dart';

class GearRepositoryImpl implements GearRepository {
  GearRepositoryImpl({required GearApi api}) : _api = api;

  final GearApi _api;

  @override
  Future<List<GearItem>> list() => _api.list();

  @override
  Future<GearItem> add(GearItem draft) => _api.add(draft);

  @override
  Future<void> remove(String id) => _api.remove(id);
}
