// lib/features/bookings/data/payment_repository_impl.dart
//
// Local-first payment repository scoped to a single booking. Mutations
// gate on `Capability.editBookingPayments` (Property 11). Aggregation is
// delegated to the DAO so the detail screen's payment summary card reads
// from a single SQL aggregate.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/bookings_dao.dart';
import '../../../core/db/daos/outbox_dao.dart';
import '../../../core/db/daos/payments_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../domain/payment.dart';
import '../domain/payment_kind.dart';
import '../domain/payment_repository.dart';
import 'payment_api.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required PaymentApi api, required AppDatabase db})
    : _api = api,
      _db = db;

  final PaymentApi _api;
  final AppDatabase _db;

  PaymentsDao get _payments => _db.paymentsDao;
  BookingsDao get _bookings => _db.bookingsDao;
  OutboxDao get _outbox => _db.outboxDao;

  Payment _rowToPayment(PaymentRow r) => Payment(
    id: r.id,
    remoteId: r.remoteId,
    bookingId: r.bookingId,
    kind: PaymentKind.values.firstWhere(
      (x) => x.name == r.kind,
      orElse: () => PaymentKind.advance,
    ),
    amount: r.amount,
    method: r.method,
    note: r.note,
    paidAt: r.paidAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    pending: r.pending,
  );

  PaymentsTableCompanion _modelToCompanion(Payment p, {required bool pending}) {
    return PaymentsTableCompanion(
      id: Value(p.id),
      remoteId: Value(p.remoteId),
      bookingId: Value(p.bookingId),
      kind: Value(p.kind.name),
      amount: Value(p.amount),
      method: Value(p.method),
      note: Value(p.note),
      paidAt: Value(p.paidAt),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      pending: Value(pending),
    );
  }

  void _verify(RolePolicy policy) {
    if (!policy.can(Capability.editBookingPayments)) {
      throw RolePolicyDeniedException(
        capability: Capability.editBookingPayments,
        role: policy.role,
      );
    }
  }

  @override
  Stream<List<Payment>> watchByBooking(String bookingId) {
    return _payments
        .watchByBooking(bookingId)
        .map((rows) => rows.map(_rowToPayment).toList(growable: false));
  }

  @override
  Future<({double advance, double due, double extra, double total})>
  aggregateForBooking(String bookingId) {
    return _payments.aggregateForBooking(bookingId);
  }

  @override
  Future<Map<String, double>> collectionByMethodBetween(
    DateTime from,
    DateTime to,
  ) {
    return _payments.collectionByMethodBetween(from, to);
  }

  @override
  Future<void> add(Payment p, {required RolePolicy policy}) async {
    _verify(policy);
    await _persist(p, op: 'create');
  }

  @override
  Future<void> update(Payment p, {required RolePolicy policy}) async {
    _verify(policy);
    await _persist(p, op: 'update');
  }

  @override
  Future<void> remove(String paymentId, {required RolePolicy policy}) async {
    _verify(policy);

    await _payments.deleteById(paymentId);
    await _outbox.enqueue(
      OutboxTableCompanion.insert(
        entityType: 'payment',
        entityId: paymentId,
        op: 'delete',
        payloadJson: jsonEncode({'id': paymentId}),
      ),
    );
  }

  Future<void> _persist(Payment p, {required String op}) async {
    final stamped = p.copyWith(updatedAt: DateTime.now(), pending: true);
    await _payments.upsert(_modelToCompanion(stamped, pending: true));

    try {
      final bookingRow = await _bookings.watchById(stamped.bookingId).first;
      final bookingRemoteId = bookingRow?.remoteId;
      if (bookingRemoteId == null) {
        await _outbox.enqueue(
          OutboxTableCompanion.insert(
            entityType: 'payment',
            entityId: stamped.id,
            op: op,
            payloadJson: jsonEncode(stamped.toJson()),
          ),
        );
        return;
      }

      final remote = op == 'create'
          ? await _api.create(bookingRemoteId, stamped)
          : await _api.patch(
              bookingRemoteId,
              stamped.remoteId ?? stamped.id,
              stamped.toJson(),
            );
      final synced = remote.copyWith(pending: false);
      await _payments.upsert(_modelToCompanion(synced, pending: false));
    } catch (e, st) {
      AppLogger.w('payment', '$op remote failed; queued in outbox: $e');
      AppLogger.e('payment', e, st);
      await _outbox.enqueue(
        OutboxTableCompanion.insert(
          entityType: 'payment',
          entityId: stamped.id,
          op: op,
          payloadJson: jsonEncode(stamped.toJson()),
        ),
      );
    }
  }
}
