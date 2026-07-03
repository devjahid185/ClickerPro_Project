import 'dart:async';

import 'package:clicker_pro/features/profile/domain/gear_item.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/features/profile/domain/user_repository.dart';

class StubUserRepository implements UserRepository {
  StubUserRepository(this._user);

  final UserModel? _user;

  @override
  Stream<UserModel?> watchCurrentUser() => Stream.value(_user);

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<void> refreshFromRemote() async {}

  @override
  Future<UserModel> updateProfile(UserModel updated) => Future.value(updated);

  @override
  Stream<List<GearItem>> watchGear(String userId) => Stream.value(<GearItem>[]);

  @override
  Future<void> addGear(GearItem item) async {}

  @override
  Future<void> removeGear(String gearId) async {}

  @override
  Future<LifetimeStats?> getLifetimeStats() async => null;
}
