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

  /// Payload for `POST /api/payments`. The Laravel PaymentController
  /// validates snake_case `event_id`, an UPPERCASE `kind`
  /// (ADVANCE/DUE/EXTRA/PAYOUT) and an UPPERCASE `method`
  /// (CASH/BKASH/NAGAD/BANK/CARD/OTHER), so map the local lowercase values
  /// up here.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'event_id': eventId,
      'amount': amount,
      'kind': type.toUpperCase(),
      'method': method.toUpperCase(),
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

  /// Tolerant of BOTH the Laravel wire shape (snake_case, int id, UPPERCASE
  /// `kind`/`method`) and the older local camelCase shape (offline cache).
  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final createdRaw = (json['created_at'] ?? json['createdAt'])?.toString();
    final rawAmount = json['amount'];
    return PaymentRecord(
      id: (json['id'] ?? '').toString(),
      eventId: (json['event_id'] ?? json['eventId'] ?? '').toString(),
      // Laravel's `decimal:2` cast (see Payment::$casts) serializes `amount`
      // as a JSON STRING (e.g. "5000.00"), not a number — this is deliberate
      // on the PHP side to avoid float precision loss. `rawAmount as num?`
      // threw a TypeError on every real payment row (a String can't cast to
      // num), which crashed list() with an exception AppLogger never saw
      // (it's not an ApiException) — the "Failed to load payments" screen
      // with no server-side error to match. Parse it string-first.
      amount: (rawAmount is num)
          ? rawAmount.toDouble()
          : double.tryParse('$rawAmount') ?? 0,
      method: ((json['method'] as String?) ?? 'cash').toLowerCase(),
      type: ((json['kind'] ?? json['type']) as String? ?? 'due').toLowerCase(),
      hidden: json['hidden'] as bool? ?? false,
      createdAt: (createdRaw == null || createdRaw.isEmpty)
          ? DateTime.now()
          : DateTime.tryParse(createdRaw) ?? DateTime.now(),
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
