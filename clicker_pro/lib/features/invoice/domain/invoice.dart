// lib/features/invoice/domain/invoice.dart
//
// Domain entity for an Invoice generated against a booking. Carries the
// full payment snapshot (total / advance / due) plus team member contact
// info so the PDF export can render the full document without extra
// fetches.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.

class Invoice {
  final String id;
  final String eventId;
  final String status;
  final String packageName;
  final double total;
  final double advance;
  final double due;
  final DateTime? sentAt;
  final List<String> teamNames;
  final List<String> teamPhones;
  final String companyName;
  final String companyPhone;

  const Invoice({
    required this.id,
    required this.eventId,
    required this.status,
    required this.packageName,
    required this.total,
    required this.advance,
    required this.due,
    this.sentAt,
    this.teamNames = const <String>[],
    this.teamPhones = const <String>[],
    this.companyName = '',
    this.companyPhone = '',
  });

  Invoice copyWith({
    String? id,
    String? eventId,
    String? status,
    String? packageName,
    double? total,
    double? advance,
    double? due,
    DateTime? sentAt,
    List<String>? teamNames,
    List<String>? teamPhones,
    String? companyName,
    String? companyPhone,
  }) {
    return Invoice(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      packageName: packageName ?? this.packageName,
      total: total ?? this.total,
      advance: advance ?? this.advance,
      due: due ?? this.due,
      sentAt: sentAt ?? this.sentAt,
      teamNames: teamNames ?? this.teamNames,
      teamPhones: teamPhones ?? this.teamPhones,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'status': status,
      'packageName': packageName,
      'total': total,
      'advance': advance,
      'due': due,
      'teamNames': teamNames,
      'teamPhones': teamPhones,
      'companyName': companyName,
      'companyPhone': companyPhone,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'status': status,
      'packageName': packageName,
      'total': total,
      'advance': advance,
      'due': due,
      if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      'teamNames': teamNames,
      'teamPhones': teamPhones,
      'companyName': companyName,
      'companyPhone': companyPhone,
    };
  }

  /// Laravel's `decimal:2` cast (Invoice::$casts — subtotal/tax_amount/total)
  /// serializes those columns as JSON STRINGS ("5000.00"), not numbers — a
  /// deliberate choice on the PHP side to avoid float precision loss. A bare
  /// `as num` cast throws a TypeError on every real invoice, which crashed
  /// invoice loading silently (a TypeError isn't an ApiException, so it never
  /// reached the app's error logging). Same root cause as the payments
  /// "Failed to load" bug in payment_record.dart.
  static double _money(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? json['event_id'] ?? '').toString(),
      status: (json['status'] as String?) ?? 'draft',
      packageName: (json['packageName'] as String?) ?? '',
      total: _money(json['total']),
      advance: _money(json['advance']),
      due: _money(json['due']),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.tryParse(json['sentAt'].toString()),
      teamNames:
          (json['teamNames'] as List?)?.cast<String>() ?? const <String>[],
      teamPhones:
          (json['teamPhones'] as List?)?.cast<String>() ?? const <String>[],
      companyName: (json['companyName'] as String?) ?? '',
      companyPhone: (json['companyPhone'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Invoice) return false;
    return id == other.id &&
        eventId == other.eventId &&
        status == other.status &&
        packageName == other.packageName &&
        total == other.total &&
        advance == other.advance &&
        due == other.due &&
        sentAt == other.sentAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    eventId,
    status,
    packageName,
    total,
    advance,
    due,
    sentAt,
  ]);

  @override
  String toString() =>
      'Invoice(id: $id, eventId: $eventId, status: $status, '
      'total: $total, advance: $advance, due: $due)';
}
