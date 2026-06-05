// lib/features/profile/domain/user_repository.dart

import 'gear_item.dart';
import 'user_model.dart';

class LifetimeStats {
  const LifetimeStats({
    required this.totalEvents,
    required this.totalRevenueMinor,
    required this.totalClients,
    this.refreshedAt,
  });

  final int totalEvents;
  final int totalRevenueMinor;
  final int totalClients;
  final DateTime? refreshedAt;
}

abstract class UserRepository {
  Stream<UserModel?> watchCurrentUser();
  Future<UserModel?> getCurrentUser();
  Future<void> refreshFromRemote();

  /// Local-first: writes to Drift first, then attempts remote.
  /// On network/5xx failure, local change persists and is enqueued in Outbox.
  Future<UserModel> updateProfile(UserModel updated);

  Stream<List<GearItem>> watchGear(String userId);
  Future<void> addGear(GearItem item);
  Future<void> removeGear(String gearId);

  Future<LifetimeStats?> getLifetimeStats();
}
