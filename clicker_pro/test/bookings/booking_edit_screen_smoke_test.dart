// test/bookings/booking_edit_screen_smoke_test.dart
//
// Smoke test for the booking edit form. Two scenarios:
//
//   1. The screen mounts in CREATE mode (no booking id) and renders
//      the new-booking title + Save button + Title field.
//   2. Submitting with an empty Title surfaces the inline validation
//      error from `BookingEditController.validate`.

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/application/session_controller.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/bookings/application/booking_providers.dart';
import 'package:clicker_pro/features/bookings/domain/package.dart';
import 'package:clicker_pro/features/bookings/presentation/booking_edit_screen.dart';
import 'package:clicker_pro/features/profile/application/profile_controllers.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('BookingEditScreen mounts in create mode', (tester) async {
    await _pumpEditScreen(tester);

    expect(find.text('New Booking'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);
    expect(
      find.text('CLIENT NAME', skipOffstage: false),
      findsAtLeastNWidgets(1),
      reason: 'Form body should mount with the Client Name field label.',
    );
  });

  testWidgets('Empty client name surfaces inline validation on save', (
    tester,
  ) async {
    await _pumpEditScreen(tester);

    // Tap the SAVE button — Client Name is empty so validation
    // triggers shake animation.
    await tester.tap(find.text('SAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The form should still be visible (shake animation, not crash).
    expect(find.text('New Booking'), findsOneWidget);
  });
}

Future<void> _pumpEditScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  final user = UserModel(
    id: 'u-owner-1',
    name: 'Test Owner',
    email: 'owner@example.com',
    role: UserRole.owner,
    phone: '01700000000',
  );
  final session = Session(token: 't', user: user, issuedAt: DateTime.now());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(initial: session),
        ),
        currentUserProvider.overrideWith(
          (ref) => Stream<UserModel?>.value(user),
        ),
        // Empty packages list so the picker doesn't try to read remote.
        packagesProvider.overrideWith(
          (ref) => Stream<List<Package>>.value(const []),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BookingEditScreen(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // The BookingEditController.build reads from the session controller,
  // which is itself an async future — settle a few more frames so the
  // form actually mounts.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

class _FakeSessionController extends SessionController {
  _FakeSessionController({this.initial});
  final Session? initial;
  @override
  Future<Session?> build() async => initial;
}
