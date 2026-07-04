// lib/features/auth/domain/user_role.dart
//
// Role system. Manager is invite-bound and cannot self-register.
// Office Staff (photo/video editors, HR, office boys…) self-register and
// set their position from the profile screen afterwards.

enum UserRole {
  owner,
  freelancer,
  both,
  manager,
  officeStaff,
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
    if (lower == 'office_staff' || lower == 'officestaff' || lower == 'staff') {
      return UserRole.officeStaff;
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
      case UserRole.officeStaff:
        return 'Office Staff';
      case UserRole.webAdmin:
        return 'Web Admin';
    }
  }

  /// Wire format used by backend payloads ('owner' | 'freelancer' | 'both' | 'manager' | 'officeStaff' | 'webAdmin').
  String get wireName => name;

  /// UPPERCASE server enum value for the Laravel `users.role` column.
  /// officeStaff needs the underscore form; the rest are plain uppercase.
  String get serverName =>
      this == UserRole.officeStaff ? 'OFFICE_STAFF' : name.toUpperCase();
}
