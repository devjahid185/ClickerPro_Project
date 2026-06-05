// See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".

import '../../../core/role/role_policy.dart';
import 'package.dart';

/// Package CRUD scoped to the current studio.
///
/// Read is unrestricted (any role can browse packages while editing a
/// booking); mutations are gated via the supplied [RolePolicy] — the
/// implementation enforces the corresponding Capability before any
/// side effect.
abstract class PackageRepository {
  /// Live local-first list of all packages for the current studio.
  Stream<List<Package>> watchAll();

  /// Upsert. Returns the persisted entity.
  Future<Package> save(Package p, {required RolePolicy policy});

  /// Removes a package by id.
  Future<void> remove(String packageId, {required RolePolicy policy});

  /// Pulls fresh rows from the server and reconciles into Drift.
  Future<void> refreshFromRemote();
}
