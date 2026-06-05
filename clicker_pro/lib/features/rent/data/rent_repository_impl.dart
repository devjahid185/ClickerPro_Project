// lib/features/rent/data/rent_repository_impl.dart

import '../domain/rent_record.dart';
import '../domain/rent_repository.dart';
import 'rent_api.dart';

class RentRepositoryImpl implements RentRepository {
  RentRepositoryImpl({required RentApi api}) : _api = api;

  final RentApi _api;

  @override
  Future<List<RentRecord>> history() => _api.history();

  @override
  Future<RentRecord> create(RentRecord draft) => _api.create(draft);

  @override
  Future<void> updateStatus({
    required String id,
    required RentStatus status,
    DateTime? actualReturnDate,
  }) => _api.updateStatus(
    id: id,
    status: status,
    actualReturnDate: actualReturnDate,
  );
}
