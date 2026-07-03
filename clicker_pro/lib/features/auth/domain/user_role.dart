// lib/features/auth/domain/user_role.dart
//
// Four-tier role system. Manager is invite-bound and cannot self-register.

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
}
