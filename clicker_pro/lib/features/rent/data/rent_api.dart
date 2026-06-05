// lib/features/rent/data/rent_api.dart

import '../../../core/network/api_client.dart';
import '../domain/rent_record.dart';

class RentApi {
  RentApi(this._client);

  final ApiClient _client;

  Future<List<RentRecord>> history() async {
    final r = await _client.get('/api/rent/history') as Map<String, dynamic>;
    final raw = (r['history'] as List?) ?? const <dynamic>[];
    return raw
        .cast<Map<String, dynamic>>()
        .map(RentRecord.fromJson)
        .toList(growable: false);
  }

  Future<RentRecord> create(RentRecord draft) async {
    final r =
        await _client.post('/api/rent/record', body: draft.toCreateJson())
            as Map<String, dynamic>;
    final created = (r['record'] as Map).cast<String, dynamic>();
    return RentRecord.fromJson(created);
  }

  Future<void> updateStatus({
    required String id,
    required RentStatus status,
    DateTime? actualReturnDate,
  }) async {
    await _client.patch(
      '/api/rent/status/$id',
      body: {
        'status': status.wire,
        if (actualReturnDate != null)
          'actualReturnDate': actualReturnDate.toIso8601String(),
      },
    );
  }
}
