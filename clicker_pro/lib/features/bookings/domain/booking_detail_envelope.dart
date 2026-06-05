// lib/features/bookings/domain/booking_detail_envelope.dart
//
// Composite read-model returned by the booking detail endpoint and the
// detail repository. Bundles the booking and every cascading side
// resource the detail screen needs in a single fetch.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports. Plain immutable
// record-style class so the booking_repository can return the same shape
// when assembling the local view.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Remote API Contract" (`GET /api/bookings/:id` returns
// `{ event, client, assignments[], payments[], package?, statusHistory[],
//   reEditRequests[], taskProgress[] }`).

import 'assignment.dart';
import 'booking.dart';
import 'client.dart';
import 'package.dart';
import 'payment.dart';
import 're_edit_request.dart';
import 'status_history_entry.dart';
import 'task_progress.dart';

/// The full booking detail payload returned by `GET /api/bookings/:id`.
///
/// Instances are immutable. Both [BookingApi.get] and
/// `BookingRepository.getDetail` return this shape so the detail screen
/// can render from a single object whether the source is the network or
/// the local Drift cache.
class BookingDetailEnvelope {
  const BookingDetailEnvelope({
    required this.booking,
    required this.client,
    required this.assignments,
    required this.payments,
    required this.package,
    required this.statusHistory,
    required this.reEditRequests,
    required this.taskProgress,
  });

  /// The booking row itself.
  final Booking booking;

  /// The linked client, when [Booking.clientId] is set and the row was
  /// found server-side. `null` if the booking has no client (e.g. fresh
  /// public-form submission still being approved).
  final Client? client;

  /// All assignments scoped to this booking.
  final List<Assignment> assignments;

  /// All payments scoped to this booking.
  final List<Payment> payments;

  /// The linked package, when [Booking.packageId] is set. `null` for
  /// custom-priced bookings.
  final Package? package;

  /// Append-only status timeline; ordered by `at` ascending.
  final List<StatusHistoryEntry> statusHistory;

  /// All re-edit requests opened against this booking.
  final List<ReEditRequest> reEditRequests;

  /// Per-staff task progress rows for this booking.
  final List<TaskProgress> taskProgress;

  /// Decodes the wire envelope returned by `GET /api/bookings/:id`.
  ///
  /// The shape mirrors the design "Remote API Contract" entry:
  /// `{ event, client, assignments[], payments[], package?,
  ///    statusHistory[], reEditRequests[], taskProgress[] }`.
  factory BookingDetailEnvelope.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> asMap(Object? v) => (v as Map).cast<String, dynamic>();

    List<Map<String, dynamic>> asList(Object? v) => (v as List? ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);

    final clientRaw = json['client'];
    final packageRaw = json['package'];

    return BookingDetailEnvelope(
      booking: Booking.fromJson(asMap(json['event'])),
      client: clientRaw == null ? null : Client.fromJson(asMap(clientRaw)),
      assignments: asList(
        json['assignments'],
      ).map(Assignment.fromJson).toList(growable: false),
      payments: asList(
        json['payments'],
      ).map(Payment.fromJson).toList(growable: false),
      package: packageRaw == null ? null : Package.fromJson(asMap(packageRaw)),
      statusHistory: asList(
        json['statusHistory'],
      ).map(StatusHistoryEntry.fromJson).toList(growable: false),
      reEditRequests: asList(
        json['reEditRequests'],
      ).map(ReEditRequest.fromJson).toList(growable: false),
      taskProgress: asList(
        json['taskProgress'],
      ).map(TaskProgress.fromJson).toList(growable: false),
    );
  }
}
