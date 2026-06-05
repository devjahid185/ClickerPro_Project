// lib/features/rent/domain/rent_record.dart
//
// Rent record — tracks gear lent OUT to others or rented IN from others।
//
// Backend response shape (controllers/rentController.js):
//   { id, direction, counterpartyName, counterpartyPhone, amount,
//     dateLent, returnBy, actualReturnDate, status, ownerId,
//     gearItemId, gear: { id, name } | null, createdAt }
//
// `direction`:
//   • 'OUT' — we lent OUR gear to someone else
//   • 'IN'  — we rented IN someone else's gear
//
// `status`:
//   • 'ACTIVE'   — open rental
//   • 'RETURNED' — closed cleanly
//   • 'OVERDUE'  — past returnBy without actualReturnDate

enum RentDirection {
  out_,
  in_;

  /// Wire format expected by backend's `direction` enum check।
  String get wire => this == RentDirection.out_ ? 'OUT' : 'IN';

  static RentDirection fromWire(String? raw) {
    return (raw ?? '').toUpperCase() == 'IN'
        ? RentDirection.in_
        : RentDirection.out_;
  }
}

enum RentStatus {
  active,
  returned,
  overdue;

  String get wire {
    switch (this) {
      case RentStatus.returned:
        return 'RETURNED';
      case RentStatus.overdue:
        return 'OVERDUE';
      case RentStatus.active:
        return 'ACTIVE';
    }
  }

  static RentStatus fromWire(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'RETURNED':
        return RentStatus.returned;
      case 'OVERDUE':
        return RentStatus.overdue;
      default:
        return RentStatus.active;
    }
  }
}

class RentRecord {
  final String id;
  final RentDirection direction;
  final String counterpartyName;
  final String? counterpartyPhone;
  final double amount;
  final DateTime? returnBy;
  final DateTime? actualReturnDate;
  final RentStatus status;
  final String? gearItemId;
  final String? gearName;
  final DateTime? createdAt;

  const RentRecord({
    required this.id,
    required this.direction,
    required this.counterpartyName,
    this.counterpartyPhone,
    required this.amount,
    this.returnBy,
    this.actualReturnDate,
    required this.status,
    this.gearItemId,
    this.gearName,
    this.createdAt,
  });

  Map<String, dynamic> toCreateJson() => {
    'direction': direction.wire,
    'counterpartyName': counterpartyName,
    if (counterpartyPhone != null) 'counterpartyPhone': counterpartyPhone,
    'amount': amount,
    if (returnBy != null) 'returnBy': returnBy!.toIso8601String(),
    if (gearItemId != null) 'gearItemId': gearItemId,
  };

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    final gear = json['gear'];
    return RentRecord(
      id: (json['id'] ?? '').toString(),
      direction: RentDirection.fromWire(json['direction'] as String?),
      counterpartyName: (json['counterpartyName'] ?? '').toString(),
      counterpartyPhone: json['counterpartyPhone'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      returnBy: json['returnBy'] == null
          ? null
          : DateTime.tryParse(json['returnBy'].toString()),
      actualReturnDate: json['actualReturnDate'] == null
          ? null
          : DateTime.tryParse(json['actualReturnDate'].toString()),
      status: RentStatus.fromWire(json['status'] as String?),
      gearItemId: json['gearItemId'] as String?,
      gearName: gear is Map ? gear['name'] as String? : null,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  /// True if `returnBy` has passed and the record is still ACTIVE।
  /// Used by the row to render an OVERDUE badge even if the backend
  /// hasn't been polled to flip the status yet।
  bool isOverdueAt(DateTime now) {
    if (status != RentStatus.active) return false;
    if (returnBy == null) return false;
    return now.isAfter(returnBy!);
  }
}
