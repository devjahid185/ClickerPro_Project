// lib/features/profile/application/profile_controllers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/role/role_policy.dart';
import '../../auth/domain/user_role.dart';
import '../domain/gear_item.dart';
import '../domain/user_model.dart';

/// Streams the locally-cached current user (Drift-backed). Updates reactively
/// across all widgets when AuthRepository / UserRepository writes happen.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(userRepositoryProvider).watchCurrentUser();
});

/// Per-user gear stream. Family parameter is the user id.
final gearListProvider = StreamProvider.family<List<GearItem>, String>(
  (ref, userId) => ref.watch(userRepositoryProvider).watchGear(userId),
);

/// Reactive RolePolicy derived from currentUserProvider. Defaults to Owner
/// while no user is loaded so capability checks during loading don't flicker.
final rolePolicyProvider = Provider<RolePolicy>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return RolePolicy(user?.role ?? UserRole.owner);
});
