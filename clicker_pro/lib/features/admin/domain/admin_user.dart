// lib/features/admin/domain/admin_user.dart
//
// Admin-side view of a platform account. Maps 1:1 onto
// `AdminController::userRow()` — deliberately excludes booking/finance data
// (see that controller's PRIVACY comments); `totalRevenueMinor` is always 0
// server-side and not surfaced here.

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.plan,
    this.businessName,
    this.totalEvents = 0,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? plan;
  final String? businessName;
  final int totalEvents;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    int n(Object? v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return AdminUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      phone: s(json['phone']),
      plan: s(json['plan']),
      businessName: s(json['businessName']),
      totalEvents: n(json['totalEvents']),
      isActive: json['deletedAt'] == null,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
