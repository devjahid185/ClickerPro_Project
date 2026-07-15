// lib/features/auth/domain/user_role.dart
//
// Role system. Manager is invite-bound and cannot self-register.
// The old OFFICE_STAFF role was removed (Heaven 2026-07-15) — the Owner
// account carries every office-staff capability instead; legacy accounts
// that still send OFFICE_STAFF resolve to the fallback role.

enum UserRole {
  owner,
  freelancer,
  both,
  manager,
  webAdmin;

  static UserRole fromString(
    String? raw, {
    UserRole fallback = UserRole.owner,
  }) {
    if (raw == null) return fallback;
    final lower = raw.toLowerCase();
    if (lower == 'admin' || lower == 'webadmin' || lower == 'web_admin') {
      return UserRole.webAdmin;
    }
    for (final r in UserRole.values) {
      if (r.name.toLowerCase() == lower) return r;
    }
    return fallback;
  }

  String get displayLabel {
    switch (this) {
      case UserRole.owner:
        return 'Company Owner';
      case UserRole.freelancer:
        return 'Freelancer';
      case UserRole.both:
        return 'Both';
      case UserRole.manager:
        return 'Manager';
      case UserRole.webAdmin:
        return 'Web Admin';
    }
  }

  /// Wire format used by backend payloads ('owner' | 'freelancer' | 'both' | 'manager' | 'webAdmin').
  String get wireName => name;

  /// UPPERCASE server enum value for the Laravel `users.role` column.
  String get serverName => name.toUpperCase();
}
