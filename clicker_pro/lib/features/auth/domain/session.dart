// lib/features/auth/domain/session.dart

import '../../profile/domain/user_model.dart';
import 'user_role.dart';

class Session {
  const Session({
    required this.token,
    required this.user,
    required this.issuedAt,
  });

  final String token;
  final UserModel user;
  final DateTime issuedAt;

  bool get isManager => user.role == UserRole.manager;

  Session copyWith({UserModel? user}) =>
      Session(token: token, user: user ?? this.user, issuedAt: issuedAt);
}
