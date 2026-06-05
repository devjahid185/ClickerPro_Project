// lib/core/role/role_policy_denied_exception.dart
//
// Thrown by repositories when a user invokes an action whose Capability gate
// fails for their role. UI catches this and shows a friendly message; tests
// match on the typed exception.

import '../../features/auth/domain/user_role.dart';
import 'capability.dart';

class RolePolicyDeniedException implements Exception {
  const RolePolicyDeniedException({
    required this.capability,
    required this.role,
    String? message,
  }) : message = message ?? 'Your role does not allow this action.';

  final Capability capability;
  final UserRole role;
  final String message;

  @override
  String toString() =>
      'RolePolicyDeniedException(capability: $capability, role: $role): $message';
}
