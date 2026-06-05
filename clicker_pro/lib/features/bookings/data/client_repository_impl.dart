// lib/features/bookings/data/client_repository_impl.dart
//
// Local-first client repository with phone-prefix autocomplete and
// background remote refresh. Mirrors `UserRepositoryImpl` for the
// upsert + outbox pattern.
//
// Phone-prefix search hits Drift only — there is no network round-trip
// per keystroke. The booking list / search bar refreshes the local cache
// in the background on app start (or via explicit `refreshFromRemote()`),
// and autocomplete reads from that cache.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/clients_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../domain/client.dart';
import '../domain/client_repository.dart';
import 'client_api.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl({required ClientApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final ClientApi _api;
  final AppDatabase _db;

  ClientsDao get _clients => _db.clientsDao;
  OutboxDao get _outbox => _db.outboxDao;

  Client _rowToClient(ClientRow r) => Client(
    id: r.id,
    remoteId: r.remoteId,
    studioId: r.studioId,
    name: r.name,
    phone: r.phone,
    email: r.email,
    address: r.address,
    dob: r.dob,
    anniversary: r.anniversary,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  ClientsTableCompanion _modelToCompanion(Client c, {required bool pending}) {
    return ClientsTableCompanion(
      id: Value(c.id),
      remoteId: Value(c.remoteId),
      studioId: Value(c.studioId),
      name: Value(c.name),
      phone: Value(c.phone),
      email: Value(c.email),
      address: Value(c.address),
      dob: Value(c.dob),
      anniversary: Value(c.anniversary),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
      pending: Value(pending),
    );
  }

  @override
  Future<List<Client>> searchByPhone(String prefix) async {
    final rows = await _clients.searchByPhone(prefix);
    return rows.map(_rowToClient).toList(growable: false);
  }

  @override
  Future<Client?> getByPhone(String phone) async {
    final row = await _clients.getByPhone(phone);
    return row == null ? null : _rowToClient(row);
  }

  @override
  Stream<Client?> watch(String localId) {
    return _clients
        .watchById(localId)
        .map((r) => r == null ? null : _rowToClient(r));
  }

  @override
  Future<Client> save(Client client) async {
    final stamped = client.copyWith(updatedAt: DateTime.now(), pending: true);
    await _clients.upsert(_modelToCompanion(stamped, pending: true));

    final isCreate = client.remoteId == null;
    try {
      final remote = isCreate
          ? await _api.create(stamped)
          : await _api.patch(client.remoteId!, stamped.toJson());
      final synced = remote.copyWith(pending: false);
      await _clients.upsert(_modelToCompanion(synced, pending: false));
      return synced;
    } catch (e, st) {
      AppLogger.w('client', 'save remote failed; queued in outbox: $e');
      AppLogger.e('client', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'client',
          entityId: stamped.id,
          op: isCreate ? 'create' : 'update',
          payloadJson: jsonEncode(stamped.toJson()),
        ),
      );
      return stamped;
    }
  }

  @override
  Future<void> refreshFromRemote() async {
    try {
      final clients = await _api.list();
      for (final c in clients) {
        await _clients.upsert(_modelToCompanion(c, pending: false));
      }
    } on ApiException catch (e, st) {
      AppLogger.w('client', 'refreshFromRemote failed: ${e.message}');
      AppLogger.e('client', e, st);
    }
  }
}
