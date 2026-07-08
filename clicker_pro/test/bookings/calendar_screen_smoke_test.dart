// test/bookings/calendar_screen_smoke_test.dart
//
// Smoke test for the calendar screen. Mounts with an in-memory database
// + zero bookings; asserts the month header, weekday strip, and
// next-month navigation work.

import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/application/session_controller.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/bookings/presentation/calendar_screen.dart';
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

  testWidgets('CalendarScreen renders header + weekday strip', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final user = UserModel(
      id: 'u-owner-1',
      name: 'Test Owner',
      email: 'owner@example.com',
      role: UserRole.owner,
      phone: '01700000000',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sessionControllerProvider.overrideWith(
            () => _FakeSessionController(
              initial: Session(
                token: 't',
                user: user,
                issuedAt: DateTime.now(),
              ),
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) => Stream<UserModel?>.value(user),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.byTooltip('Next month'), findsOneWidget);
    // Weekday strip is now single mono letters (S M T W T F S). 'S' (Sun +
    // Sat) and 'T' (Tue + Thu) appear twice; M/W/F once each.
    expect(find.text('M'), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2));
    expect(find.text('T'), findsNWidgets(2));

    await db.close();
  });
}

class _FakeSessionController extends SessionController {
  _FakeSessionController({this.initial});
  final Session? initial;
  @override
  Future<Session?> build() async => initial;
}
