// lib/features/bookings/application/booking_conflict.dart
//
// Pure scheduling-conflict rules for new/edited bookings.
//
// Two distinct rules per the v12 architecture:
//
//   • Freelancer (R-01) — strict 1 event per shift. A second booking on
//     the same date + shift is a HARD BLOCK, with no bypass even when
//     Distribution mode is on (Key Decisions → "Freelancer booking limit").
//
//   • Owner / Both (R-02 / R-03) — a same date + shift booking raises a
//     WARNING the user can override. With Distribution mode ON the warning
//     is suppressed entirely (multiple bookings per slot are expected).
//
// Pure Dart — no Flutter / Riverpod / Drift imports so it can be unit
// tested exhaustively.

import '../../../core/booking_status/booking_status.dart';
import '../../auth/domain/user_role.dart';
import '../domain/booking.dart';
import '../domain/shift.dart';

/// The kind of clash a candidate booking has against the existing list.
enum BookingConflictLevel {
  /// No clash — safe to save silently.
  none,

  /// Same date + shift already booked. Owner/Both may override.
  warning,

  /// Freelancer's strict 1-per-shift limit hit — cannot save.
  block,
}

class BookingConflictResult {
  const BookingConflictResult(this.level, {this.clashingTitle});

  final BookingConflictLevel level;

  /// Title of an existing clashing booking, for the warning/error copy.
  final String? clashingTitle;

  bool get isBlock => level == BookingConflictLevel.block;
  bool get isWarning => level == BookingConflictLevel.warning;
  bool get isClear => level == BookingConflictLevel.none;
}

class BookingConflict {
  const BookingConflict._();

  /// Two shifts clash when they cover any overlapping part of the day.
  /// `both` (full day) overlaps every other shift.
  static bool _shiftsClash(Shift a, Shift b) {
    if (a == Shift.both || b == Shift.both) return true;
    return a == b;
  }

  /// Evaluates the candidate against [existing] for the given [role].
  ///
  /// [candidateId] is excluded from the scan so editing a booking never
  /// conflicts with itself. [distributionOn] only relaxes the Owner/Both
  /// warning — it never unlocks the Freelancer hard block.
  static BookingConflictResult evaluate({
    required UserRole role,
    required bool freelancerMode,
    required DateTime? date,
    required Shift shift,
    required String candidateId,
    required List<Booking> existing,
    required bool distributionOn,
  }) {
    if (date == null) return const BookingConflictResult(BookingConflictLevel.none);
    final day = DateTime(date.year, date.month, date.day);

    final clashes = existing.where((b) {
      if (b.id == candidateId) return false;
      if (b.status == BookingStatus.cancelled) return false;
      final bDay = DateTime(b.date.year, b.date.month, b.date.day);
      return bDay == day && _shiftsClash(b.shift, shift);
    }).toList();

    if (clashes.isEmpty) {
      return const BookingConflictResult(BookingConflictLevel.none);
    }

    // Freelancer (including a Both-role user in freelancer mode) is hard
    // capped at 1 event per shift — no override.
    final isFreelancerBooking = role == UserRole.freelancer || freelancerMode;
    if (isFreelancerBooking) {
      return BookingConflictResult(
        BookingConflictLevel.block,
        clashingTitle: clashes.first.title,
      );
    }

    // Owner / Both: Distribution mode lets them stack multiple bookings on
    // the same slot without a warning.
    if (distributionOn) {
      return const BookingConflictResult(BookingConflictLevel.none);
    }

    return BookingConflictResult(
      BookingConflictLevel.warning,
      clashingTitle: clashes.first.title,
    );
  }
}
