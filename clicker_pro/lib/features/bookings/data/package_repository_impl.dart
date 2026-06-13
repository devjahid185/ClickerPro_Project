// lib/features/bookings/data/package_repository_impl.dart
//
// Local-first package repository scoped to the current studio. Mutations
// gate on `Capability.editStudioBranding` (Owner / Both per the design's
// matrix — managing packages is part of studio configuration, not
// per-booking edit). Reads are unrestricted.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/packages_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../domain/package.dart';
import '../domain/package_repository.dart';
import 'package_api.dart';

class PackageRepositoryImpl implements PackageRepository {
  PackageRepositoryImpl({required PackageApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final PackageApi _api;
  final AppDatabase _db;

  PackagesDao get _packages => _db.packagesDao;
  OutboxDao get _outbox => _db.outboxDao;

  Package _rowToPackage(PackageRow r) => Package(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    name: r.name,
    basePrice: r.basePrice,
    discount: r.discount,
    coverageHours: r.coverageHours,
    extraHourRate: r.extraHourRate,
    printSize: r.printSize,
    printQuantity: r.printQuantity,
    albumText: r.albumText,
    deliveryMethod: r.deliveryMethod,
    trailersPerEvent: r.trailersPerEvent,
    fullVideosPerEvent: r.fullVideosPerEvent,
    photographerCount: r.photographerCount,
    cinematographerCount: r.cinematographerCount,
    includesChief: r.includesChief,
    items: _decodeJsonStringList(r.itemsJson),
    inclusions: _decodeJsonStringList(r.inclusionsJson),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  PackagesTableCompanion _modelToCompanion(Package p, {required bool pending}) {
    return PackagesTableCompanion(
      id: Value(p.id),
      remoteId: Value(p.remoteId),
      studioId: Value(p.studioId),
      name: Value(p.name),
      basePrice: Value(p.basePrice),
      discount: Value(p.discount),
      coverageHours: Value(p.coverageHours),
      extraHourRate: Value(p.extraHourRate),
      printSize: Value(p.printSize),
      printQuantity: Value(p.printQuantity),
      albumText: Value(p.albumText),
      deliveryMethod: Value(p.deliveryMethod),
      trailersPerEvent: Value(p.trailersPerEvent),
      fullVideosPerEvent: Value(p.fullVideosPerEvent),
      photographerCount: Value(p.photographerCount),
      cinematographerCount: Value(p.cinematographerCount),
      includesChief: Value(p.includesChief),
      itemsJson: Value(_encodeJsonStringList(p.items)),
      inclusionsJson: Value(_encodeJsonStringList(p.inclusions)),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      pending: Value(pending),
    );
  }

  void _verify(RolePolicy policy) {
    if (!policy.can(Capability.editStudioBranding)) {
      throw RolePolicyDeniedException(
        capability: Capability.editStudioBranding,
        role: policy.role,
      );
    }
  }

  @override
  Stream<List<Package>> watchAll() {
    return _packages.watchAll().map(
      (rows) => rows.map(_rowToPackage).toList(growable: false),
    );
  }

  @override
  Future<Package> save(Package p, {required RolePolicy policy}) async {
    _verify(policy);

    final stamped = p.copyWith(updatedAt: DateTime.now(), pending: true);
    await _packages.upsert(_modelToCompanion(stamped, pending: true));

    final isCreate = p.remoteId == null;
    try {
      final remote = isCreate
          ? await _api.create(stamped)
          : await _api.patch(p.remoteId!, stamped.toJson());
      final synced = remote.copyWith(pending: false);
      await _packages.upsert(_modelToCompanion(synced, pending: false));
      return synced;
    } catch (e, st) {
      AppLogger.w('package', 'save remote failed; queued in outbox: $e');
      AppLogger.e('package', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'package',
          entityId: stamped.id,
          op: isCreate ? 'create' : 'update',
          payloadJson: jsonEncode(stamped.toJson()),
        ),
      );
      return stamped;
    }
  }

  @override
  Future<void> remove(String packageId, {required RolePolicy policy}) async {
    _verify(policy);

    await _packages.deleteById(packageId);
    await _outbox.enqueue(
      OutboxTableCompanion.insert(
        entityType: 'package',
        entityId: packageId,
        op: 'delete',
        payloadJson: jsonEncode({'id': packageId}),
      ),
    );
  }

  @override
  Future<void> refreshFromRemote() async {
    try {
      final pkgs = await _api.list();
      for (final p in pkgs) {
        await _packages.upsert(_modelToCompanion(p, pending: false));
      }
    } on ApiException catch (e, st) {
      AppLogger.w('package', 'refreshFromRemote failed: ${e.message}');
      AppLogger.e('package', e, st);
    }
  }

  String? _encodeJsonStringList(List<String>? list) {
    if (list == null) return null;
    return jsonEncode(list);
  }

  List<String>? _decodeJsonStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e == null ? '' : e.toString())
            .toList(growable: false);
      }
    } catch (_) {
      // Fall through.
    }
    return null;
  }
}
