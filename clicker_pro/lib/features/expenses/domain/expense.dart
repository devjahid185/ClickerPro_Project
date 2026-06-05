// lib/features/expenses/domain/expense.dart
//
// Domain entity for an Expense — money outflow recorded against the
// studio's owner.  Unlike Payment, an Expense is not bound to a single
// Booking; it may optionally reference one (e.g., "Studio rent for the
// Karim wedding") but free-floating expenses ("monthly software
// subscription") are common.
//
// Pure Dart — no Flutter, Drift, Riverpod imports.  Currency formatting
// happens at display time via `BookingFormat.money`.
//
// Backend wire format (`backend/src/controllers/expenseController.js`):
//   { id, amount, category, eventId?, ownerId, note?, date, syncStatus,
//     remoteRev, createdAt? }
// We intentionally keep the wire payload tolerant — older client builds
// shipped without `note`, and the server returns Date objects that we
// coerce to ISO strings on read.

class Expense {
  /// Server-assigned id (uuid).  Local-only state would normally use a
  /// separate local id, but for the MVP slice we are online-first, so the
  /// server id is canonical.
  final String id;

  /// Optional studio-owner id — backend always populates this from the
  /// authenticated user.  We carry it back through so role-scoped UIs can
  /// double-check before display.
  final String? ownerId;

  /// Free-form category string, e.g. `'Travel' | 'Equipment' | 'Software'
  /// | 'Salary'`.  Kept as a string rather than an enum so studios can
  /// invent categories without a release.
  final String category;

  /// Expense amount.  Stored verbatim; formatting happens at the view
  /// layer.
  final double amount;

  /// Optional booking link.  When set, the expense rolls up into the
  /// per-booking P&L on the booking detail screen.
  final String? eventId;

  /// Free-form note attached to the expense.
  final String? note;

  /// Optional uploaded receipt URL (cloudinary-style host).  May be null
  /// when the user didn't attach a photo.
  final String? receiptUrl;

  /// When the expense was actually incurred (back-dating allowed).  The
  /// backend column is named `date`; we surface it as `incurredAt` to
  /// match the booking module's `paidAt` convention.
  final DateTime incurredAt;

  /// Wall-clock timestamp at first creation.  May be null on freshly
  /// created records that haven't round-tripped to the server.
  final DateTime? createdAt;

  const Expense({
    required this.id,
    this.ownerId,
    required this.category,
    required this.amount,
    this.eventId,
    this.note,
    this.receiptUrl,
    required this.incurredAt,
    this.createdAt,
  });

  Expense copyWith({
    String? id,
    String? ownerId,
    String? category,
    double? amount,
    String? eventId,
    String? note,
    String? receiptUrl,
    DateTime? incurredAt,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      eventId: eventId ?? this.eventId,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      incurredAt: incurredAt ?? this.incurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Wire-format payload sent to `POST /api/expenses`.  We deliberately
  /// omit server-managed fields (`id`, `ownerId`, `createdAt`) on the way
  /// up — the controller derives them server-side.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'amount': amount,
      'category': category,
      if (eventId != null) 'eventId': eventId,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'date': incurredAt.toIso8601String(),
    };
  }

  /// Full wire payload — used when updating or echoing back.  Includes
  /// the server-managed fields so we can round-trip exactly the row we
  /// fetched.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (ownerId != null) 'ownerId': ownerId,
      'category': category,
      'amount': amount,
      if (eventId != null) 'eventId': eventId,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'date': incurredAt.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Tolerant parser — accepts both the `POST` response shape and the
  /// `GET /api/expenses` row shape.  Numeric fields may arrive as `int`
  /// or `double` depending on JSON precision, so we coerce via `num`.
  factory Expense.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] ?? json['incurredAt'];
    final createdRaw = json['createdAt'];
    return Expense(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String?,
      category: (json['category'] as String?) ?? 'Other',
      amount: (json['amount'] as num).toDouble(),
      eventId: json['eventId'] as String?,
      note: json['note'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      incurredAt: dateRaw == null
          ? DateTime.now()
          : DateTime.parse(dateRaw as String),
      createdAt: createdRaw == null
          ? null
          : DateTime.parse(createdRaw as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expense) return false;
    return id == other.id &&
        ownerId == other.ownerId &&
        category == other.category &&
        amount == other.amount &&
        eventId == other.eventId &&
        note == other.note &&
        receiptUrl == other.receiptUrl &&
        incurredAt == other.incurredAt &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    ownerId,
    category,
    amount,
    eventId,
    note,
    receiptUrl,
    incurredAt,
    createdAt,
  ]);

  @override
  String toString() =>
      'Expense(id: $id, category: $category, amount: $amount, '
      'incurredAt: $incurredAt)';
}
