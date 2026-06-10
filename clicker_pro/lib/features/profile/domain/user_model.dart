// lib/features/profile/domain/user_model.dart
//
// Canonical user profile object used across UI + repositories.
// Mirrors the UsersTable Drift row plus Lifetime stats.

import '../../auth/domain/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.remoteId,
    this.phone,
    this.whatsapp,
    this.bio,
    this.avatarUrl,
    this.specialization,
    this.companyName,
    this.vatBin,
    this.studioAddress,
    this.bkash,
    this.bankDetails,
    this.signatureUrl,
    this.logoUrl,
    this.ownerId,
    this.totalEvents = 0,
    this.totalRevenueMinor = 0,
    this.totalClients = 0,
    this.statsRefreshedAt,
    this.deletedAt,
  });

  final String id;
  final String? remoteId;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? whatsapp;
  final String? bio;
  final String? avatarUrl;
  final String? specialization;
  final String? companyName;
  final String? vatBin;
  final String? studioAddress;
  final String? bkash;
  final String? bankDetails;
  final String? signatureUrl;
  final String? logoUrl;
  final String? ownerId;
  final int totalEvents;
  final int totalRevenueMinor;
  final int totalClients;
  final DateTime? statsRefreshedAt;
  final DateTime? deletedAt;

  /// Avatar initials: first letters of first two name parts (e.g. "Karim Rahman" → "KR").
  String get avatarInitials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Subtitle shown under brand: "Company · Karim" / "Freelancer · Karim".
  String get studioLabel {
    final firstName = name.trim().split(' ').first;
    switch (role) {
      case UserRole.owner:
      case UserRole.both:
        return 'Company · $firstName';
      case UserRole.freelancer:
        return 'Freelancer · $firstName';
      case UserRole.manager:
        return 'Manager · $firstName';
      case UserRole.webAdmin:
        return 'Admin · $firstName';
    }
  }

  bool get isPendingDeletion => deletedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backends (incl. Prisma) may send `id` as a String, int, or under
    // alternate keys. Coerce to String so a numeric/missing id can never
    // throw a TypeError and crash the app on login.
    final rawId = json['id'] ?? json['_id'] ?? json['userId'];
    final id = rawId?.toString() ?? '';

    return UserModel(
      id: id,
      remoteId: (json['remoteId'] ?? rawId)?.toString(),
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: UserRole.fromString(json['role'] as String?),
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      bio: json['bio'] as String?,
      // Laravel UserResource sends snake_case (`avatar`, `business_name`)
      // alongside some camelCase aliases — accept both spellings.
      avatarUrl: (json['avatarUrl'] ?? json['avatar']) as String?,
      specialization: json['specialization'] as String?,
      companyName:
          json['companyName'] as String? ??
          json['businessName'] as String? ??
          json['business_name'] as String?,
      vatBin: json['vatBin'] as String?,
      studioAddress: json['studioAddress'] as String?,
      bkash: json['bkash'] as String?,
      bankDetails: json['bankDetails'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      totalRevenueMinor: (json['totalRevenueMinor'] as num?)?.toInt() ?? 0,
      totalClients: (json['totalClients'] as num?)?.toInt() ?? 0,
      statsRefreshedAt: _parseDate(json['statsRefreshedAt']),
      deletedAt: _parseDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (remoteId != null) 'remoteId': remoteId,
    'name': name,
    'email': email,
    'role': role.name,
    if (phone != null) 'phone': phone,
    if (whatsapp != null) 'whatsapp': whatsapp,
    if (bio != null) 'bio': bio,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (specialization != null) 'specialization': specialization,
    if (companyName != null) 'companyName': companyName,
    if (vatBin != null) 'vatBin': vatBin,
    if (studioAddress != null) 'studioAddress': studioAddress,
    if (bkash != null) 'bkash': bkash,
    if (bankDetails != null) 'bankDetails': bankDetails,
    if (signatureUrl != null) 'signatureUrl': signatureUrl,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (ownerId != null) 'ownerId': ownerId,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? remoteId,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? whatsapp,
    String? bio,
    String? avatarUrl,
    String? specialization,
    String? companyName,
    String? vatBin,
    String? studioAddress,
    String? bkash,
    String? bankDetails,
    String? signatureUrl,
    String? logoUrl,
    String? ownerId,
    int? totalEvents,
    int? totalRevenueMinor,
    int? totalClients,
    DateTime? statsRefreshedAt,
    Object? deletedAt = _sentinel,
  }) {
    return UserModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      specialization: specialization ?? this.specialization,
      companyName: companyName ?? this.companyName,
      vatBin: vatBin ?? this.vatBin,
      studioAddress: studioAddress ?? this.studioAddress,
      bkash: bkash ?? this.bkash,
      bankDetails: bankDetails ?? this.bankDetails,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerId: ownerId ?? this.ownerId,
      totalEvents: totalEvents ?? this.totalEvents,
      totalRevenueMinor: totalRevenueMinor ?? this.totalRevenueMinor,
      totalClients: totalClients ?? this.totalClients,
      statsRefreshedAt: statsRefreshedAt ?? this.statsRefreshedAt,
      deletedAt: identical(deletedAt, _sentinel)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  static const _sentinel = Object();

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
