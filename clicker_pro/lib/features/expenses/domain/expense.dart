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

  /// Wire-format payload sent to `POST /api/expenses`.
  ///
  /// The Laravel `ExpenseController@store` validates snake_case fields and
  /// **requires** a non-null `title` and `date`. The Flutter UI collects a
  /// category + note but no separate title, so we derive the title from the
  /// note (falling back to the category) to satisfy the validator. Server
  /// managed fields (`id`, `owner_id`, timestamps) are omitted — the
  /// controller derives them from the authenticated user.
  Map<String, dynamic> toCreateJson() {
    final title = (note != null && note!.trim().isNotEmpty)
        ? note!.trim()
        : category;
    return <String, dynamic>{
      'title': title,
      'amount': amount,
      'category': category,
      if (eventId != null) 'event_id': eventId,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      // Laravel casts the column to `date`; send a plain yyyy-MM-dd so it
      // parses cleanly regardless of timezone.
      'date':
          '${incurredAt.year.toString().padLeft(4, '0')}-'
          '${incurredAt.month.toString().padLeft(2, '0')}-'
          '${incurredAt.day.toString().padLeft(2, '0')}',
    };
  }

  /// Full wire payload — used when updating or echoing back. Mirrors the
  /// snake_case column names the Laravel backend persists.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'category': category,
      'amount': amount,
      if (eventId != null) 'event_id': eventId,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      'date': incurredAt.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Tolerant parser for the Laravel row shape (and the older Node contract).
  ///
  /// Laravel returns **integer** ids, **string** decimals ("100.00"), and
  /// snake_case columns; the legacy Node backend returned string ids,
  /// numeric amounts, and camelCase. We accept both by coercing ids to
  /// String, parsing amounts through `num`/`String`, and checking snake_case
  /// keys first with a camelCase fallback.
  factory Expense.fromJson(Map<String, dynamic> json) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) {
          final s = v.toString();
          if (s.isNotEmpty) return s;
        }
      }
      return null;
    }

    final amountRaw = json['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '') ?? 0;

    final dateRaw = pick(['date', 'incurredAt']);
    final createdRaw = pick(['created_at', 'createdAt']);

    return Expense(
      // ids arrive as int (Laravel) or String (Node) — coerce to String.
      id: json['id'].toString(),
      ownerId: pick(['owner_id', 'ownerId']),
      category: pick(['category']) ?? 'Other',
      amount: amount,
      eventId: pick(['event_id', 'eventId']),
      note: pick(['note']),
      receiptUrl: pick(['receipt_url', 'receiptUrl']),
      incurredAt: dateRaw == null
          ? DateTime.now()
          : (DateTime.tryParse(dateRaw) ?? DateTime.now()),
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
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
