// lib/features/profile/data/user_repository_impl.dart

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/gear_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/users_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/user_role.dart';
import '../domain/gear_item.dart';
import '../domain/user_model.dart';
import '../domain/user_repository.dart';
import 'user_api.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required UserApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final UserApi _api;
  final AppDatabase _db;

  UsersDao get _users => _db.usersDao;
  GearDao get _gear => _db.gearDao;
  OutboxDao get _outbox => _db.outboxDao;

  UserModel _rowToModel(UserRow row) => UserModel(
    id: row.id,
    remoteId: row.remoteId,
    name: row.name,
    email: row.email,
    role: UserRole.fromString(row.role),
    phone: row.phone,
    whatsapp: row.whatsapp,
    ownerId: row.ownerId,
    avatarUrl: row.avatarUrl,
    bio: row.bio,
    specialization: row.specialization,
    vatBin: row.vatBin,
    studioAddress: row.studioAddress,
    bkash: row.bkash,
    bankDetails: row.bankDetails,
    signatureUrl: row.signatureUrl,
    logoUrl: row.logoUrl,
    deletedAt: row.deletedAt,
  );

  GearItem _gearRowToModel(GearItemRow r) => GearItem(
    id: r.id,
    userId: r.userId,
    name: r.name,
    brand: r.brand,
    remoteId: r.remoteId,
    addedAt: r.addedAt,
  );

  UsersTableCompanion _modelToCompanion(UserModel u) => UsersTableCompanion(
    id: Value(u.id),
    remoteId: Value(u.remoteId),
    name: Value(u.name),
    email: Value(u.email),
    phone: Value(u.phone),
    role: Value(u.role.wireName),
    ownerId: Value(u.ownerId),
    avatarUrl: Value(u.avatarUrl),
    bio: Value(u.bio),
    specialization: Value(u.specialization),
    vatBin: Value(u.vatBin),
    studioAddress: Value(u.studioAddress),
    whatsapp: Value(u.whatsapp),
    bkash: Value(u.bkash),
    bankDetails: Value(u.bankDetails),
    signatureUrl: Value(u.signatureUrl),
    logoUrl: Value(u.logoUrl),
    deletedAt: Value(u.deletedAt),
    updatedAt: Value(DateTime.now()),
  );

  @override
  Stream<UserModel?> watchCurrentUser() =>
      _users.watchCurrent().map((row) => row == null ? null : _rowToModel(row));

  @override
  Future<UserModel?> getCurrentUser() async {
    final row = await _users.getCurrent();
    return row == null ? null : _rowToModel(row);
  }

  @override
  Future<void> refreshFromRemote() async {
    try {
      final json = await _api.getProfile();
      final user = UserModel.fromJson(json);
      await _users.upsertCurrent(_modelToCompanion(user));
    } on ApiException catch (e, st) {
      AppLogger.w('user', 'refreshFromRemote failed: ${e.message}');
      AppLogger.e('user', e, st);
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel updated) async {
    // Local-first durability per Requirement 6.1 / Property 12.
    await _users.upsertCurrent(
      _modelToCompanion(updated).copyWith(pending: const Value(true)),
    );

    try {
      final json = await _api.patchProfile(updated.toJson());
      final remoteCopy = UserModel.fromJson(json);
      // The server only persists name/phone/bio/business_name/avatar —
      // merge its authoritative values into the FULL local model so the
      // device-only fields (whatsapp, bkash, signature, logo, …) survive.
      final merged = updated.copyWith(
        name: remoteCopy.name.isNotEmpty ? remoteCopy.name : null,
        phone: remoteCopy.phone,
        bio: remoteCopy.bio,
        companyName: remoteCopy.companyName,
        avatarUrl: remoteCopy.avatarUrl,
        remoteId: remoteCopy.remoteId,
      );
      await _users.upsertCurrent(
        _modelToCompanion(merged).copyWith(pending: const Value(false)),
      );
      return merged;
    } catch (e, st) {
      AppLogger.w('user', 'updateProfile remote failed; queued in outbox: $e');
      AppLogger.e('user', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'user',
          entityId: updated.id,
          op: 'update',
          payloadJson: jsonEncode(updated.toJson()),
        ),
      );
      // Return the locally-saved version so UI still updates.
      return updated;
    }
  }

  @override
  Stream<List<GearItem>> watchGear(String userId) => _gear
      .watchByUserId(userId)
      .map((rows) => rows.map(_gearRowToModel).toList());

  @override
  Future<void> addGear(GearItem item) async {
    await _gear.insertGear(
      GearItemsTableCompanion.insert(
        id: item.id,
        userId: item.userId,
        name: item.name,
        brand: Value(item.brand),
        pending: const Value(true),
      ),
    );
    try {
      final json = await _api.addGear(name: item.name, brand: item.brand);
      // Replace pending row with confirmed remote one.
      await _gear.insertGear(
        GearItemsTableCompanion(
          id: Value(item.id),
          remoteId: Value(json['id'] as String?),
          userId: Value(item.userId),
          name: Value(item.name),
          brand: Value(item.brand),
          pending: const Value(false),
        ),
      );
    } catch (e, st) {
      AppLogger.w('user', 'addGear remote failed; queued in outbox: $e');
      AppLogger.e('user', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'gear',
          entityId: item.id,
          op: 'create',
          payloadJson: jsonEncode({
            'id': item.id,
            'name': item.name,
            'brand': item.brand,
          }),
        ),
      );
    }
  }

  @override
  Future<void> removeGear(String gearId) async {
    await _gear.markDeleted(gearId);
    try {
      await _api.removeGear(gearId);
      await _gear.hardDelete(gearId);
    } catch (e, st) {
      AppLogger.w('user', 'removeGear remote failed; queued in outbox: $e');
      AppLogger.e('user', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'gear',
          entityId: gearId,
          op: 'delete',
          payloadJson: jsonEncode({'id': gearId}),
        ),
      );
    }
  }

  @override
  Future<LifetimeStats?> getLifetimeStats() async {
    final json = await _api.getLifetimeStats();
    if (json == null) return null;
    return LifetimeStats(
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      totalRevenueMinor: (json['totalRevenueMinor'] as num?)?.toInt() ?? 0,
      totalClients: (json['totalClients'] as num?)?.toInt() ?? 0,
      refreshedAt: DateTime.now(),
    );
  }
}
