// lib/features/bookings/domain/booking_filter.dart
//
// Value object that captures the criteria applied to the booking list
// query. Threaded through `bookingListProvider(filter)` as the family key,
// so equality MUST be value-based or the family will leak duplicate
// providers.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 1.3, 1.6, 2.1, 7.4, 13.1.

import '../../../core/booking_status/booking_status.dart';
import 'booking_sort.dart';
import 'event_type.dart';

/// Filter criteria for the booking list and month-of-bookings queries.
///
/// All collection fields default to immutable empty sets; nullable scalars
/// default to `null`. The default constructor returns a fully empty filter
/// for which [isEmpty] is `true`.
///
/// Use [copyWith] to produce a modified filter without mutating the
/// original — instances are immutable so they can be safely shared as the
/// `bookingListProvider` family key.
class BookingFilter {
  /// Inclusive lower bound on `Booking.date`.
  final DateTime? from;

  /// Inclusive upper bound on `Booking.date`.
  final DateTime? to;

  /// Restrict results to bookings whose `status` is in this set.
  ///
  /// An empty set means "no status restriction" — every status is
  /// returned.
  final Set<BookingStatus> statuses;

  /// Restrict results to bookings whose `eventType` is in this set.
  ///
  /// An empty set means "no event-type restriction".
  final Set<EventType> types;

  /// Restrict results to bookings whose `clientId` matches.
  final String? clientId;

  /// Free-text search applied across booking title and client name.
  final String? search;

  /// Sort order applied to the result. Defaults to [BookingSort.dateDesc].
  final BookingSort sort;

  const BookingFilter({
    this.from,
    this.to,
    this.statuses = const {},
    this.types = const {},
    this.clientId,
    this.search,
    this.sort = BookingSort.dateDesc,
  });

  /// True iff every field is at its default / empty value.
  ///
  /// Used by the list screen to decide whether to render the "Clear
  /// filters" affordance and by the month-query path to short-circuit to
  /// the unfiltered watch.
  bool get isEmpty =>
      from == null &&
      to == null &&
      statuses.isEmpty &&
      types.isEmpty &&
      clientId == null &&
      (search == null || search!.isEmpty) &&
      sort == BookingSort.dateDesc;

  /// Returns a copy of this filter with the given fields replaced.
  ///
  /// Pass [clearFrom], [clearTo], [clearClientId], or [clearSearch] to
  /// explicitly null-out the corresponding nullable field — passing `null`
  /// for those parameters cannot be distinguished from "leave unchanged",
  /// so the explicit `clear*` flags fill that gap.
  BookingFilter copyWith({
    DateTime? from,
    DateTime? to,
    Set<BookingStatus>? statuses,
    Set<EventType>? types,
    String? clientId,
    String? search,
    BookingSort? sort,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearClientId = false,
    bool clearSearch = false,
  }) {
    return BookingFilter(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      search: clearSearch ? null : (search ?? this.search),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookingFilter) return false;
    return from == other.from &&
        to == other.to &&
        _setEquals(statuses, other.statuses) &&
        _setEquals(types, other.types) &&
        clientId == other.clientId &&
        search == other.search &&
        sort == other.sort;
  }

  @override
  int get hashCode => Object.hash(
    from,
    to,
    // Order-independent hash for the status / type sets so equal sets
    // with different iteration order still hash to the same bucket.
    _setHash(statuses),
    _setHash(types),
    clientId,
    search,
    sort,
  );

  @override
  String toString() =>
      'BookingFilter('
      'from: $from, to: $to, '
      'statuses: $statuses, types: $types, '
      'clientId: $clientId, search: $search, sort: $sort)';
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final element in a) {
    if (!b.contains(element)) return false;
  }
  return true;
}

int _setHash<T>(Set<T> s) {
  if (s.isEmpty) return 0;
  // XOR combine so the hash is independent of iteration order.
  var h = 0;
  for (final element in s) {
    h ^= element.hashCode;
  }
  return h;
}
