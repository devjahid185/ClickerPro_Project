// lib/features/admin/domain/admin_stats.dart
//
// Platform-wide, non-financial counts from `GET /api/admin/stats`. The
// backend deliberately excludes any studio's booking/revenue data — the
// admin sees only aggregate account/broadcast/ticket counts.

class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.owners,
    required this.freelancers,
    required this.admins,
    required this.totalClients,
    required this.activeBroadcasts,
    required this.openTickets,
    this.unresolvedCrashes = 0,
  });

  final int totalUsers;
  final int owners;
  final int freelancers;
  final int admins;
  final int totalClients;
  final int activeBroadcasts;
  final int openTickets;
  final int unresolvedCrashes;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    int n(Object? v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    return AdminStats(
      totalUsers: n(json['totalUsers']),
      owners: n(json['owners']),
      freelancers: n(json['freelancers']),
      admins: n(json['admins']),
      totalClients: n(json['totalClients']),
      activeBroadcasts: n(json['activeBroadcasts']),
      openTickets: n(json['openTickets']),
      unresolvedCrashes: n(json['unresolvedCrashes']),
    );
  }

  static const empty = AdminStats(
    totalUsers: 0,
    owners: 0,
    freelancers: 0,
    admins: 0,
    totalClients: 0,
    activeBroadcasts: 0,
    openTickets: 0,
    unresolvedCrashes: 0,
  );
}
