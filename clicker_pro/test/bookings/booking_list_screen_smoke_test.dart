// test/bookings/booking_list_screen_smoke_test.dart
//
// Smoke test for the first end-to-end booking surface. Mounts the
// screen with an in-memory database + a fake session controller, pumps
// frames, and asserts the screen header lands. This guards against
// regressions in:
//
//   • app_router → BookingListScreen wiring
//   • bookingListProvider stream + role-scope predicate (with a
//     freshly-created Owner who has zero bookings)
//   • shared async-state widgets (LensLoader → EmptyState)

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/application/session_controller.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/bookings/presentation/booking_list_screen.dart';
import 'package:clicker_pro/features/profile/application/profile_controllers.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('BookingListScreen renders empty state for a fresh studio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final user = UserModel(
      id: 'u-owner-1',
      name: 'Test Owner',
      email: 'owner@example.com',
      role: UserRole.owner,
      phone: '01700000000',
    );
    final session = Session(
      token: 'test-token',
      user: user,
      issuedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sessionControllerProvider.overrideWith(
            () => _FakeSessionController(initial: session),
          ),
          // Force the cached-user stream to emit our test user
          // synchronously so the BookingListScreen's `currentUserId`
          // resolves on the first frame and the bookings stream can
          // emit its empty list.
          currentUserProvider.overrideWith(
            (ref) => Stream<UserModel?>.value(user),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BookingListScreen(),
        ),
      ),
    );

    // Pump several frames to let:
    //  1. Riverpod providers resolve (session, currentUser, rolePolicy)
    //  2. The async* generator in bookingListProvider complete its
    //     _resolveStudioId await and delegate to the Drift stream
    //  3. Drift emit the initial empty list on the watchList query
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Bookings'), findsOneWidget);
    // The empty-state copy renders when the StreamProvider yields an
    // empty list — see `_emptyStateMessage` in the screen.
    expect(
      find.textContaining('No bookings yet'),
      findsOneWidget,
      reason: 'Empty-state copy should appear for an Owner with zero bookings.',
    );
    // FAB is visible because Owner satisfies `Capability.createBooking`.
    expect(find.textContaining('New Booking'), findsOneWidget);

    await db.close();
  });
}

/// Minimal fake `SessionController` whose `build` resolves to a fixed
/// session. Avoids real network / SecureStore touches in the test
/// pump.
class _FakeSessionController extends SessionController {
  _FakeSessionController({this.initial});

  final Session? initial;

  @override
  Future<Session?> build() async => initial;
}
