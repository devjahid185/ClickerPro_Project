// lib/features/public_booking/application/public_booking_providers.dart
//
// Provider tree for the public booking flow. Two faces:
//
//   • Visitor side  (unauthenticated) — used by `PublicBookingFormScreen`.
//     Accepts a token, peeks at it, and submits a request. No auth, no
//     role policy.
//
//   • Owner side    (authenticated)   — used by the booking list's
//     "Pending requests" surface. Lists pending submissions and lets
//     the Owner / Both approve or reject each one.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../bookings/application/booking_providers.dart';
import '../../profile/application/profile_controllers.dart';
import '../data/public_booking_api.dart';
import '../data/public_booking_repository_impl.dart';
import '../domain/public_booking_repository.dart';
import '../domain/public_booking_request.dart';
import '../domain/public_booking_token.dart';

final publicBookingApiProvider = Provider<PublicBookingApi>(
  (ref) => PublicBookingApi(ref.read(apiClientProvider)),
);

final publicBookingRepositoryProvider = Provider<PublicBookingRepository>((
  ref,
) {
  return PublicBookingRepositoryImpl(
    api: ref.read(publicBookingApiProvider),
    db: ref.read(appDatabaseProvider),
    bookingRepo: ref.read(bookingRepositoryProvider),
    ownerPolicy: ref.read(rolePolicyProvider),
  );
});

/// Family-keyed peek: hands a token in, gets back the studio metadata
/// the form needs to render.
final publicBookingTokenProvider =
    FutureProvider.family<PublicBookingToken, String>((ref, token) {
      return ref.read(publicBookingRepositoryProvider).peek(token);
    });

/// Pending public-booking requests for the current studio.
final pendingPublicBookingsProvider =
    StreamProvider<List<PublicBookingRequest>>(
      (ref) => ref.read(publicBookingRepositoryProvider).watchPending(),
    );
