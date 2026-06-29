// lib/features/team/domain/staff_payout.dart
//
// Owner-side staff/freelancer payout summary. Each [StaffPayout] groups all
// of one team member's assignment earnings across the owner's events, with a
// per-event [PayoutItem] breakdown so "3 events = 3 payouts" reads at a glance
// and a tap can reveal which event paid what.
//
// Pure Dart — no Flutter/Drift/Riverpod imports.

class StaffPayoutSheet {
  const StaffPayoutSheet({
    required this.totalEarned,
    required this.totalPaid,
    required this.members,
  });

  final double totalEarned;
  final double totalPaid;
  final List<StaffPayout> members;

  double get totalDue =>
      (totalEarned - totalPaid) > 0 ? totalEarned - totalPaid : 0;

  bool get hasOutstanding => totalDue > 0.5;

  factory StaffPayoutSheet.fromJson(Map<String, dynamic> json) {
    return StaffPayoutSheet(
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      members:
          (json['members'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(StaffPayout.fromJson)
              .toList(growable: false) ??
          const <StaffPayout>[],
    );
  }

  static const empty = StaffPayoutSheet(
    totalEarned: 0,
    totalPaid: 0,
    members: <StaffPayout>[],
  );

  Map<String, dynamic> toJson() => {
    'totalEarned': totalEarned,
    'totalPaid': totalPaid,
    'members': members.map((m) => m.toJson()).toList(),
  };
}

class StaffPayout {
  const StaffPayout({
    required this.userId,
    required this.name,
    this.avatar,
    required this.events,
    required this.earned,
    required this.paid,
    required this.due,
    required this.items,
  });

  final String userId;
  final String name;
  final String? avatar;
  final int events;
  final double earned;
  final double paid;
  final double due;
  final List<PayoutItem> items;

  bool get isFullyPaid => due <= 0.5;

  factory StaffPayout.fromJson(Map<String, dynamic> json) {
    return StaffPayout(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatar: json['avatar'] as String?,
      events: (json['events'] as num?)?.toInt() ?? 0,
      earned: (json['earned'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      due: (json['due'] as num?)?.toDouble() ?? 0,
      items:
          (json['items'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(PayoutItem.fromJson)
              .toList(growable: false) ??
          const <PayoutItem>[],
    );
  }

  StaffPayout copyWith({
    double? paid,
    double? due,
    List<PayoutItem>? items,
  }) => StaffPayout(
    userId: userId,
    name: name,
    avatar: avatar,
    events: events,
    earned: earned,
    paid: paid ?? this.paid,
    due: due ?? this.due,
    items: items ?? this.items,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'avatar': avatar,
    'events': events,
    'earned': earned,
    'paid': paid,
    'due': due,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class PayoutItem {
  const PayoutItem({
    required this.assignmentId,
    required this.eventId,
    required this.eventTitle,
    this.date,
    required this.role,
    required this.amount,
    required this.paid,
  });

  final String assignmentId;
  final String eventId;
  final String eventTitle;
  final DateTime? date;
  final String role;
  final double amount;
  final bool paid;

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      assignmentId: (json['assignmentId'] ?? '').toString(),
      eventId: (json['eventId'] ?? '').toString(),
      eventTitle: (json['eventTitle'] ?? 'Event').toString(),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      role: (json['role'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paid: json['paid'] as bool? ?? false,
    );
  }

  PayoutItem copyWith({bool? paid}) => PayoutItem(
    assignmentId: assignmentId,
    eventId: eventId,
    eventTitle: eventTitle,
    date: date,
    role: role,
    amount: amount,
    paid: paid ?? this.paid,
  );

  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'eventId': eventId,
    'eventTitle': eventTitle,
    'date': date?.toIso8601String(),
    'role': role,
    'amount': amount,
    'paid': paid,
  };
}
