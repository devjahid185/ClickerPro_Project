// lib/features/bookings/domain/booking_repository.dart
//
// Domain interface for booking operations. See `.kiro/specs/bookings-module/design.md` → "Components and Interfaces".
//
// The concrete implementation is in `data/booking_repository_impl.dart`.
// This file contains only abstract contracts to keep the domain layer
// independent of infrastructure concerns (Drift, HTTP, etc.).

import '../../../core/role/role_policy.dart';
import '../domain/booking.dart';
import '../domain/booking_filter.dart';
import '../domain/booking_detail_envelope.dart';

/// Interface for booking CRUD operations with role-aware scoping and
/// local-first persistence via Drift. The concrete implementation lives
// in `data/booking_repository_impl.dart`.
abstract class BookingRepository {
  /// Watch paginated list of bookings filtered by `BookingFilter`.
  ///
  /// The `policy` and `currentUserId` params are used to scope results
  /// by role (e.g. Owner sees only their studio's bookings).
  Stream<List<Booking>> watchList(
    BookingFilter filter, {
    required RolePolicy policy,
    required String currentUserId,
    required int page,
    int pageSize = 20,
  });

  /// Watch a single booking by local id.
  Stream<Booking?> watch(String localId);

  /// Watch EVERY booking matching `filter` + role scope, unpaginated.
  ///
  /// For aggregate consumers (dashboard metrics, finance totals, the
  /// double-booking conflict guard) that must reason over the studio's
  /// entire booking set rather than whatever page the list screen has
  /// scrolled to. Prefer [watchList] for anything that renders a
  /// scrollable list.
  Stream<List<Booking>> watchAll(
    BookingFilter filter, {
    required RolePolicy policy,
    required String currentUserId,
  });

  /// Watch bookings for a specific month (year + month).
  Stream<List<Booking>> watchMonth(
    int year,
    int month, {
    required RolePolicy policy,
    required String currentUserId,
  });

  /// Fetch single booking by local id.
  Future<Booking> getById(String localId);

  /// Resolves a booking by its server-side id (e.g. from global search
  /// results). Returns null when the row hasn't synced locally yet.
  Future<Booking?> getByRemoteId(String remoteId);

  /// Fetch full booking detail envelope (booking + client + assignments
  /// + payments + package + statusHistory + reEditRequests + taskProgress).
  Future<BookingDetailEnvelope> getDetail(String localId);

  /// Fetch a single page from the remote API (used for manual refresh).
  Future<List<Booking>> fetchPage(
    BookingFilter filter, {
    required int page,
    int pageSize = 20,
  });

  /// Sync remote data into local Drift.
  Future<void> refreshFromRemote({
    BookingFilter? filter,
    String? singleEventId,
  });

  /// Upsert booking. Capability-gated via `RolePolicy`.
  Future<Booking> save(Booking booking, {required RolePolicy policy});

  /// Delete booking. Capability-gated via `RolePolicy`.
  Future<void> delete(String localId, {required RolePolicy policy});
}
