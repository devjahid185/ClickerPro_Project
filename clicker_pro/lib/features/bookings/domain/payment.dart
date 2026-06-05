// lib/features/bookings/domain/payment.dart
//
// Domain entity for a Payment recorded against a booking. Three kinds —
// advance, due, extra — tally into the booking's finance summary card and
// the overall finance dashboard.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 5.2, 13.10.

import 'payment_kind.dart';

/// A payment recorded against a booking. Values may be created out of
/// order (an `extra` paid before the original `due` is fine) — the finance
/// summary aggregates by [kind] when totaling.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
class Payment {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Local id of the parent [Booking].
  final String bookingId;

  /// Kind of payment — drives which bucket it tallies into on the finance
  /// summary.
  final PaymentKind kind;

  /// Payment amount. Stored verbatim; currency formatting happens at
  /// display time via `BookingFormat.money`.
  final double amount;

  /// Free-form payment method (`'cash' | 'bank' | 'bkash' | 'nagad' | 'other'`).
  /// Kept as a string rather than an enum so studios can introduce new
  /// methods without a release.
  final String? method;

  /// Free-form note attached to the payment row.
  final String? note;

  /// When the payment was actually received. Distinct from [createdAt]
  /// because back-dating receipts is common.
  final DateTime? paidAt;

  /// Wall-clock timestamp at first creation.
  final DateTime createdAt;

  /// Most recent edit timestamp; reconciled via last-write-wins.
  final DateTime updatedAt;

  /// True while the payment has unsynced changes in the outbox.
  final bool pending;

  Payment({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.kind,
    required this.amount,
    this.method,
    this.note,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
  });

  Payment copyWith({
    String? id,
    String? remoteId,
    String? bookingId,
    PaymentKind? kind,
    double? amount,
    String? method,
    String? note,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) {
    return Payment(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      note: note ?? this.note,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'bookingId': bookingId,
      'kind': kind.name,
      'amount': amount,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      bookingId: json['bookingId'] as String,
      kind: PaymentKind.values.firstWhere(
        (k) => k.name == json['kind'] as String,
        orElse: () => PaymentKind.advance,
      ),
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String?,
      note: json['note'] as String?,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Payment) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        bookingId == other.bookingId &&
        kind == other.kind &&
        amount == other.amount &&
        method == other.method &&
        note == other.note &&
        paidAt == other.paidAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    bookingId,
    kind,
    amount,
    method,
    note,
    paidAt,
    createdAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'Payment(id: $id, bookingId: $bookingId, kind: ${kind.name}, '
      'amount: $amount)';
}
