// test/bookings/re_edit_section_smoke_test.dart
//
// Smoke test for the ReEditSection mounted inside the booking detail
// screen. Three scenarios:
//
//   • A delivered booking with one existing re-edit request renders
//     the section header and the round chip.
//   • The "Request re-edit" button is visible (Owner has the
//     `requestReEdit` capability AND status is in the eligible set).
//   • An overdue request (deadline in the past, status pending)
//     surfaces the OVERDUE badge.
//
// Mounting goes through `BookingDetailScreen` → `ReEditSection` so the
// integration with `BookingDetailController` + `bookingsPolicyProvider`
// is exercised end-to-end.

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/application/session_controller.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/bookings/application/booking_providers.dart';
import 'package:clicker_pro/features/bookings/domain/booking.dart';
import 'package:clicker_pro/features/bookings/domain/booking_detail_envelope.dart';
import 'package:clicker_pro/features/bookings/domain/booking_filter.dart';
import 'package:clicker_pro/features/bookings/domain/booking_repository.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/re_edit_request.dart';
import 'package:clicker_pro/features/bookings/domain/re_edit_status.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/bookings/presentation/booking_detail_screen.dart';
import 'package:clicker_pro/features/bookings/presentation/widgets/payment_summary_card.dart';
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

  testWidgets(
    'ReEditSection renders existing request + Request affordance + overdue badge',
    (tester) async {
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

      final now = DateTime(2025, 6, 1, 10);
      final pastDeadline = now.subtract(const Duration(days: 7));

      final booking = Booking(
        id: 'b1',
        studioId: 'u-owner-1',
        createdByUserId: 'u-owner-1',
        title: 'Acme Garden Wedding',
        eventType: EventType.wedding,
        date: now,
        startTime: '14:00',
        endTime: '22:00',
        shift: Shift.both,
        // Status must be in the eligible set for the Request affordance
        // to render. `delivered` is canonical for a re-edit window.
        status: BookingStatus.delivered,
        createdAt: now,
        updatedAt: now,
      );

      // One overdue, pending request.
      final reEdit = ReEditRequest(
        id: 're1',
        bookingId: 'b1',
        round: 1,
        editorUserId: 'u-editor-1',
        deadline: pastDeadline,
        notes: 'Tweak skin tones across the gallery.',
        status: ReEditStatus.pending,
        requestedByUserId: 'u-owner-1',
        requestedAt: now,
        updatedAt: now,
      );

      final envelope = BookingDetailEnvelope(
        booking: booking,
        client: null,
        assignments: const [],
        payments: const [],
        package: null,
        statusHistory: const [],
        reEditRequests: [reEdit],
        taskProgress: const [],
      );

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
            bookingRepositoryProvider.overrideWithValue(
              _FakeBookingRepository(envelope),
            ),
            paymentAggregateProvider('b1').overrideWith(
              (_) async => (advance: 0.0, due: 0.0, extra: 0.0, total: 0.0),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BookingDetailScreen(bookingId: 'b1'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Section title + round chip + overdue badge live near the
      // bottom of the ListView; scroll until the section title comes
      // into the lazy-build window.
      final listFinder = find.byType(ListView);
      await tester.dragUntilVisible(
        find.text('RE-EDIT REQUESTS', skipOffstage: false),
        listFinder,
        const Offset(0, -120),
      );
      await tester.dragUntilVisible(
        find.text('Round 1', skipOffstage: false),
        listFinder,
        const Offset(0, -120),
      );

      // Owner satisfies `requestReEdit`; the affordance is mounted.
      expect(
        find.byTooltip('Request re-edit', skipOffstage: false),
        findsOneWidget,
      );
      // Overdue badge shows because the seeded deadline is past + status
      // is still pending.
      expect(find.text('OVERDUE', skipOffstage: false), findsOneWidget);

      await db.close();
    },
  );
}

class _FakeSessionController extends SessionController {
  _FakeSessionController({this.initial});
  final Session? initial;
  @override
  Future<Session?> build() async => initial;
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository(this._envelope);
  final BookingDetailEnvelope _envelope;

  @override
  Future<BookingDetailEnvelope> getDetail(String localId) async => _envelope;

  @override
  Future<void> refreshFromRemote({
    BookingFilter? filter,
    String? singleEventId,
  }) async {}

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeBookingRepository.${invocation.memberName} is not stubbed.',
    );
  }
}
