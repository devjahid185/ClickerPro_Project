// lib/features/freelancer/domain/fl_earning.dart
//
// Domain models for the Freelancer Earnings Dashboard (FL-01 – FL-04).
//
//   FL-01  Earnings Overview   → FlEarningsOverview
//   FL-02  Per-Owner Card      → FlOwnerEarning
//   FL-03  Pending Payment     → FlPendingPayment
//   FL-04  Monthly Chart       → FlMonthlyEarning + FlYearlyRecap
//
// Pure Dart — no framework imports.  Currency formatting at the view layer
// via `BookingFormat.money`.

/// FL-01 — Top-level earnings snapshot for the current period.
class FlEarningsOverview {
  /// Total earnings this month (received + pending).
  final double totalEarnings;

  /// Amount already received this month.
  final double receivedAmount;

  /// Amount still pending this month.
  final double pendingAmount;

  /// Per-owner breakdown cards (FL-02).
  final List<FlOwnerEarning> owners;

  /// Pending payments list (FL-03).
  final List<FlPendingPayment> pendingPayments;

  /// Per-event unpaid payouts — which specific shoots still owe this
  /// freelancer money ("কোন কোন ইভেন্টের পেমেন্ট পাবে"). Empty when the
  /// server predates the field.
  final List<FlPendingEvent> pendingEvents;

  /// Monthly chart + yearly recap (FL-04).
  final FlYearlyRecap yearlyRecap;

  const FlEarningsOverview({
    required this.totalEarnings,
    required this.receivedAmount,
    required this.pendingAmount,
    required this.owners,
    required this.pendingPayments,
    this.pendingEvents = const <FlPendingEvent>[],
    required this.yearlyRecap,
  });

  factory FlEarningsOverview.fromJson(Map<String, dynamic> json) {
    return FlEarningsOverview(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      owners:
          (json['owners'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlOwnerEarning.fromJson)
              .toList(growable: false) ??
          const <FlOwnerEarning>[],
      pendingPayments:
          (json['pendingPayments'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlPendingPayment.fromJson)
              .toList(growable: false) ??
          const <FlPendingPayment>[],
      pendingEvents:
          (json['pendingEvents'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlPendingEvent.fromJson)
              .toList(growable: false) ??
          const <FlPendingEvent>[],
      yearlyRecap: json['yearlyRecap'] is Map<String, dynamic>
          ? FlYearlyRecap.fromJson(json['yearlyRecap'] as Map<String, dynamic>)
          : const FlYearlyRecap(monthly: [], bestMonth: null, bestOwner: null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlEarningsOverview &&
          totalEarnings == other.totalEarnings &&
          receivedAmount == other.receivedAmount &&
          pendingAmount == other.pendingAmount &&
          owners.length == other.owners.length &&
          pendingPayments.length == other.pendingPayments.length);

  @override
  int get hashCode => Object.hash(
    totalEarnings,
    receivedAmount,
    pendingAmount,
    owners.length,
    pendingPayments.length,
  );
}

/// One unpaid per-event payout — which shoot still owes the freelancer.
class FlPendingEvent {
  final String eventId;
  final String eventTitle;
  final DateTime? date;
  final String ownerName;
  final String role;
  final double amount;

  const FlPendingEvent({
    required this.eventId,
    required this.eventTitle,
    this.date,
    required this.ownerName,
    required this.role,
    required this.amount,
  });

  factory FlPendingEvent.fromJson(Map<String, dynamic> json) {
    return FlPendingEvent(
      eventId: (json['eventId'] ?? '').toString(),
      eventTitle: (json['eventTitle'] ?? 'Event').toString(),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      ownerName: (json['ownerName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// FL-02 — Per-owner breakdown card.
class FlOwnerEarning {
  final String ownerId;
  final String ownerName;
  final int eventsCount;
  final double earnedAmount;
  final double pendingAmount;
  final DateTime? lastPaymentDate;

  const FlOwnerEarning({
    required this.ownerId,
    required this.ownerName,
    required this.eventsCount,
    required this.earnedAmount,
    required this.pendingAmount,
    this.lastPaymentDate,
  });

  factory FlOwnerEarning.fromJson(Map<String, dynamic> json) {
    return FlOwnerEarning(
      ownerId: (json['ownerId'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
      earnedAmount: (json['earnedAmount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      lastPaymentDate: json['lastPaymentDate'] == null
          ? null
          : DateTime.tryParse(json['lastPaymentDate'].toString()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlOwnerEarning &&
          ownerId == other.ownerId &&
          ownerName == other.ownerName &&
          eventsCount == other.eventsCount &&
          earnedAmount == other.earnedAmount &&
          pendingAmount == other.pendingAmount);

  @override
  int get hashCode =>
      Object.hash(ownerId, ownerName, eventsCount, earnedAmount, pendingAmount);
}

/// FL-03 — Pending payment tracker entry.
class FlPendingPayment {
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final double amount;
  final int pendingDays;
  final DateTime? lastPaymentDate;

  const FlPendingPayment({
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.amount,
    required this.pendingDays,
    this.lastPaymentDate,
  });

  factory FlPendingPayment.fromJson(Map<String, dynamic> json) {
    return FlPendingPayment(
      ownerId: (json['ownerId'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      ownerPhone: (json['ownerPhone'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      pendingDays: (json['pendingDays'] as num?)?.toInt() ?? 0,
      lastPaymentDate: json['lastPaymentDate'] == null
          ? null
          : DateTime.tryParse(json['lastPaymentDate'].toString()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlPendingPayment &&
          ownerId == other.ownerId &&
          amount == other.amount &&
          pendingDays == other.pendingDays);

  @override
  int get hashCode => Object.hash(ownerId, amount, pendingDays);
}

/// FL-04 — Single monthly data point for the bar chart.
class FlMonthlyEarning {
  final String month;
  final double amount;

  const FlMonthlyEarning({required this.month, required this.amount});

  factory FlMonthlyEarning.fromJson(Map<String, dynamic> json) {
    return FlMonthlyEarning(
      month: (json['month'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlMonthlyEarning &&
          month == other.month &&
          amount == other.amount);

  @override
  int get hashCode => Object.hash(month, amount);
}

/// FL-04 — Yearly recap with best-month and best-owner stats.
class FlYearlyRecap {
  final List<FlMonthlyEarning> monthly;
  final FlMonthStat? bestMonth;
  final FlOwnerStat? bestOwner;

  const FlYearlyRecap({required this.monthly, this.bestMonth, this.bestOwner});

  factory FlYearlyRecap.fromJson(Map<String, dynamic> json) {
    return FlYearlyRecap(
      monthly:
          (json['monthly'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(FlMonthlyEarning.fromJson)
              .toList(growable: false) ??
          const <FlMonthlyEarning>[],
      bestMonth: json['bestMonth'] is Map<String, dynamic>
          ? FlMonthStat.fromJson(json['bestMonth'] as Map<String, dynamic>)
          : null,
      bestOwner: json['bestOwner'] is Map<String, dynamic>
          ? FlOwnerStat.fromJson(json['bestOwner'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlYearlyRecap && monthly.length == other.monthly.length);

  @override
  int get hashCode => monthly.length;
}

class FlMonthStat {
  final String month;
  final double amount;

  const FlMonthStat({required this.month, required this.amount});

  factory FlMonthStat.fromJson(Map<String, dynamic> json) {
    return FlMonthStat(
      month: (json['month'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlMonthStat && month == other.month && amount == other.amount);

  @override
  int get hashCode => Object.hash(month, amount);
}

class FlOwnerStat {
  final String ownerName;
  final double totalEarned;
  final int eventsCount;

  const FlOwnerStat({
    required this.ownerName,
    required this.totalEarned,
    required this.eventsCount,
  });

  factory FlOwnerStat.fromJson(Map<String, dynamic> json) {
    return FlOwnerStat(
      ownerName: (json['ownerName'] ?? '').toString(),
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlOwnerStat && ownerName == other.ownerName);

  @override
  int get hashCode => ownerName.hashCode;
}
