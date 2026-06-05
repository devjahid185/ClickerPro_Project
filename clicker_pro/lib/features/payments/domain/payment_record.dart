// lib/features/payments/domain/payment_record.dart
//
// Domain entity for a PaymentRecord logged against a booking. Distinct
// from the bookings-level Payment in that this module is the standalone
// payment tracking feature with its own bottom-sheet entry flow.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

class PaymentRecord {
  final String id;
  final String eventId;
  final double amount;
  final String method;
  final String type;
  final bool hidden;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.method,
    required this.type,
    this.hidden = false,
    required this.createdAt,
  });

  PaymentRecord copyWith({
    String? id,
    String? eventId,
    double? amount,
    String? method,
    String? type,
    bool? hidden,
    DateTime? createdAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      type: type ?? this.type,
      hidden: hidden ?? this.hidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'amount': amount,
      'method': method,
      'type': type,
      'hidden': hidden,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'amount': amount,
      'method': method,
      'type': type,
      'hidden': hidden,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: (json['method'] as String?) ?? 'cash',
      type: (json['type'] as String?) ?? 'due',
      hidden: json['hidden'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaymentRecord) return false;
    return id == other.id &&
        eventId == other.eventId &&
        amount == other.amount &&
        method == other.method &&
        type == other.type &&
        hidden == other.hidden;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[id, eventId, amount, method, type, hidden]);

  @override
  String toString() =>
      'PaymentRecord(id: $id, eventId: $eventId, amount: $amount, '
      'method: $method, type: $type)';
}
