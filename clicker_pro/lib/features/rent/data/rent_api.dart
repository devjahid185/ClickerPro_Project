// lib/features/rent/data/rent_api.dart
//
// Rent endpoints against the Laravel backend.
//
// Laravel contract (routes/api.php + RentController):
//   GET    /api/rent        → { data: [record…] }  (owner-wide history)
//   POST   /api/rent        → { data: record } (201)
//   PATCH  /api/rent/:id    → { data: record }     (mark returned)
//
// Column map: counterpartyName ⇄ rented_to · actualReturnDate ⇄
// returned_at · status is DERIVED (returned_at set → RETURNED, else
// ACTIVE; OVERDUE is computed locally from returnBy, which has no server
// column yet and stays device-local).

import '../../../core/network/api_client.dart';
import '../domain/rent_record.dart';

class RentApi {
  RentApi(this._client);

  final ApiClient _client;

  RentRecord _fromServer(Map<String, dynamic> j) {
    final gear = j['gear_item'] ?? j['gear'];
    final returnedAt = j['returned_at'] ?? j['actualReturnDate'];
    return RentRecord(
      id: (j['id'] ?? '').toString(),
      direction: RentDirection.fromWire(j['direction'] as String?),
      counterpartyName: (j['rented_to'] ?? j['counterpartyName'] ?? '')
          .toString(),
      counterpartyPhone: j['counterpartyPhone'] as String?,
      amount: double.tryParse((j['amount'] ?? '0').toString()) ?? 0,
      returnBy: j['returnBy'] == null
          ? null
          : DateTime.tryParse(j['returnBy'].toString()),
      actualReturnDate: returnedAt == null
          ? null
          : DateTime.tryParse(returnedAt.toString()),
      status: returnedAt != null ? RentStatus.returned : RentStatus.active,
      gearItemId: (j['gear_item_id'] ?? j['gearItemId'])?.toString(),
      gearName: gear is Map ? gear['name'] as String? : null,
      createdAt: DateTime.tryParse(
        (j['rented_at'] ?? j['created_at'] ?? '').toString(),
      ),
    );
  }

  Future<List<RentRecord>> history() async {
    final r = await _client.get('/api/rent');
    final raw = r is Map ? (r['data'] ?? r['history'] ?? const []) : r;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => _fromServer(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<RentRecord> create(RentRecord draft) async {
    final r = await _client.post(
      '/api/rent',
      body: {
        if (draft.gearItemId != null)
          'gear_item_id':
              int.tryParse(draft.gearItemId!) ?? draft.gearItemId,
        'direction': draft.direction.wire,
        'rented_to': draft.counterpartyName,
        'amount': draft.amount,
        'rented_at': (draft.createdAt ?? DateTime.now())
            .toIso8601String()
            .split('T')
            .first,
        if (draft.counterpartyPhone != null)
          'notes': 'Phone: ${draft.counterpartyPhone}',
      },
    );
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final created = _fromServer(d);
    // Keep the device-only fields the server cannot store yet.
    return RentRecord(
      id: created.id.isNotEmpty ? created.id : draft.id,
      direction: created.direction,
      counterpartyName: created.counterpartyName.isNotEmpty
          ? created.counterpartyName
          : draft.counterpartyName,
      counterpartyPhone: draft.counterpartyPhone,
      amount: created.amount,
      returnBy: draft.returnBy,
      actualReturnDate: created.actualReturnDate,
      status: created.status,
      gearItemId: created.gearItemId ?? draft.gearItemId,
      gearName: created.gearName ?? draft.gearName,
      createdAt: created.createdAt ?? draft.createdAt,
    );
  }

  Future<void> updateStatus({
    required String id,
    required RentStatus status,
    DateTime? actualReturnDate,
  }) async {
    await _client.patch(
      '/api/rent/$id',
      body: {
        'status': status.wire,
        if (status == RentStatus.returned)
          'returned_at': (actualReturnDate ?? DateTime.now())
              .toIso8601String()
              .split('T')
              .first,
      },
    );
  }
}
