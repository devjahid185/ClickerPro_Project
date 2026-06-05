// lib/features/public_booking/data/public_booking_repository_impl.dart
//
// Public booking flow: owner-side token issuance + approve/reject of
// pending visitor submissions, and visitor-side (unauthenticated) peek
// + submit against an HMAC token.
//
// Owner-side methods gate on `Capability.generatePublicBookingToken` /
// `Capability.approvePublicBooking` (Property 11). Visitor-side methods
// rely on the server's HMAC token verification — there is no role check
// because there is no authenticated user.

import 'package:drift/drift.dart' show Value;

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/public_booking_requests_dao.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../core/role/role_policy_denied_exception.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_repository.dart';
import '../domain/public_booking_repository.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_request_status.dart';
import '../domain/public_booking_token.dart';
import 'public_booking_api.dart';

class PublicBookingRepositoryImpl implements PublicBookingRepository {
  PublicBookingRepositoryImpl({
    required PublicBookingApi api,
    required AppDatabase db,
    required BookingRepository bookingRepo,
    required RolePolicy ownerPolicy,
  }) : _api = api,
       _db = db,
       _bookingRepo = bookingRepo,
       _ownerPolicy = ownerPolicy;

  final PublicBookingApi _api;
  final AppDatabase _db;
  final BookingRepository _bookingRepo;

  /// Stashed RolePolicy used when materializing approved bookings via
  /// `BookingRepository.save`. The owner-policy is the only role that
  /// can land here, so we capture it once at construction time.
  final RolePolicy _ownerPolicy;

  PublicBookingRequestsDao get _pending => _db.publicBookingRequestsDao;

  PublicBookingRequest _rowToRequest(PublicBookingRequestRow r) =>
      PublicBookingRequest.fromJson({
        'id': r.id,
        'studioId': r.studioId,
        'title': r.title,
        'eventType': r.eventType,
        'date': r.date.toIso8601String(),
        'startTime': r.startTime,
        'endTime': r.endTime,
        'shift': r.shift,
        if (r.venue != null) 'venue': r.venue,
        if (r.brideName != null) 'brideName': r.brideName,
        if (r.groomName != null) 'groomName': r.groomName,
        'clientName': r.clientName,
        'clientPhone': r.clientPhone,
        if (r.clientEmail != null) 'clientEmail': r.clientEmail,
        if (r.notes != null) 'notes': r.notes,
        'status': r.status,
        'submittedAt': r.submittedAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      });

  PublicBookingRequestsTableCompanion _modelToCompanion(
    PublicBookingRequest r,
  ) {
    return PublicBookingRequestsTableCompanion(
      id: Value(r.id),
      studioId: Value(r.studioId),
      title: Value(r.title),
      eventType: Value(r.eventType.name),
      date: Value(r.date),
      startTime: Value(r.startTime),
      endTime: Value(r.endTime),
      shift: Value(r.shift.name),
      venue: Value(r.venue),
      brideName: Value(r.brideName),
      groomName: Value(r.groomName),
      clientName: Value(r.clientName),
      clientPhone: Value(r.clientPhone),
      clientEmail: Value(r.clientEmail),
      notes: Value(r.notes),
      status: Value(r.status.name),
      submittedAt: Value(r.submittedAt),
      updatedAt: Value(r.updatedAt),
    );
  }

  // ───────────────────────── Owner side ─────────────────────────

  @override
  Future<({String url, String token, DateTime expiresAt})> issueToken({
    required RolePolicy policy,
  }) async {
    if (!policy.can(Capability.generatePublicBookingToken)) {
      throw RolePolicyDeniedException(
        capability: Capability.generatePublicBookingToken,
        role: policy.role,
      );
    }
    return _api.issueToken();
  }

  // ───────────────────────── Visitor side ─────────────────────────

  @override
  Future<PublicBookingToken> peek(String token) => _api.peek(token);

  @override
  Future<String> submit({
    required String token,
    required PublicBookingRequest payload,
  }) {
    return _api.submit(token, payload);
  }

  // ───────────────────── Owner side: pending list ─────────────────────

  @override
  Stream<List<PublicBookingRequest>> watchPending() {
    return _pending.watchPending().map(
      (rows) => rows.map(_rowToRequest).toList(growable: false),
    );
  }

  @override
  Future<void> refreshPending() async {
    try {
      final pending = await _api.listPending();
      for (final r in pending) {
        if (r.status == PublicBookingRequestStatus.pending) {
          await _pending.upsertPending(_modelToCompanion(r));
        }
      }
    } on ApiException catch (e, st) {
      AppLogger.w('publicBooking', 'refreshPending failed: ${e.message}');
      AppLogger.e('publicBooking', e, st);
    }
  }

  @override
  Future<Booking> approve(
    String requestId, {
    required RolePolicy policy,
  }) async {
    if (!policy.can(Capability.approvePublicBooking)) {
      throw RolePolicyDeniedException(
        capability: Capability.approvePublicBooking,
        role: policy.role,
      );
    }

    final eventJson = await _api.approve(requestId);
    final booking = Booking.fromJson(eventJson);
    // Materialize the booking locally via the booking repository so the
    // standard upsert + cascading-cache path applies. The server has
    // already created the row; we tag it `pending: false` since the
    // remote state is canonical.
    final saved = await _bookingRepo.save(
      booking.copyWith(pending: false),
      policy: _ownerPolicy,
    );
    await _pending.removeById(requestId);
    return saved;
  }

  @override
  Future<void> reject(String requestId, {required RolePolicy policy}) async {
    if (!policy.can(Capability.approvePublicBooking)) {
      throw RolePolicyDeniedException(
        capability: Capability.approvePublicBooking,
        role: policy.role,
      );
    }

    await _api.reject(requestId);
    await _pending.removeById(requestId);
  }
}
