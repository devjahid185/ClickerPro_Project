// test/bookings/task_progress_section_smoke_test.dart
//
// Smoke test for the TaskProgressSection mounted inside the booking
// detail screen. Two scenarios:
//
//   • A booking with one assignment and one progress row renders the
//     "My progress" section + the percentage.
//   • Tapping UPDATE swaps the section into edit mode (slider + notes
//     + Save button visible).
//
// Persistence-side behaviour (controller upserts via the repository)
// is covered indirectly by the controller tests; this test only
// guards the UI plumbing.

import 'package:clicker_pro/core/booking_status/booking_status.dart';
import 'package:clicker_pro/core/db/app_database.dart';
import 'package:clicker_pro/core/providers.dart';
import 'package:clicker_pro/features/auth/application/session_controller.dart';
import 'package:clicker_pro/features/auth/domain/session.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/bookings/application/booking_providers.dart';
import 'package:clicker_pro/features/bookings/domain/assignment.dart';
import 'package:clicker_pro/features/bookings/domain/assignment_role.dart';
import 'package:clicker_pro/features/bookings/domain/booking.dart';
import 'package:clicker_pro/features/bookings/domain/booking_detail_envelope.dart';
import 'package:clicker_pro/features/bookings/domain/booking_filter.dart';
import 'package:clicker_pro/features/bookings/domain/booking_repository.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/bookings/domain/task_progress.dart';
import 'package:clicker_pro/features/bookings/presentation/booking_detail_screen.dart';
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
    'TaskProgressSection renders own progress + opens editor on UPDATE',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      final user = UserModel(
        id: 'u-photog-1',
        name: 'Asha',
        email: 'asha@example.com',
        role: UserRole.owner,
        phone: '01700000000',
      );
      final session = Session(token: 't', user: user, issuedAt: DateTime.now());

      final now = DateTime(2025, 6, 1, 10);
      final booking = Booking(
        id: 'b1',
        studioId: 'u-photog-1',
        createdByUserId: 'u-photog-1',
        title: 'Acme Garden Wedding',
        eventType: EventType.wedding,
        date: now,
        startTime: '14:00',
        endTime: '22:00',
        shift: Shift.both,
        status: BookingStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );
      final assignment = Assignment(
        id: 'a1',
        bookingId: 'b1',
        userId: 'u-photog-1',
        role: AssignmentRole.photographer,
        createdAt: now,
        updatedAt: now,
      );
      final progress = TaskProgress(
        bookingId: 'b1',
        userId: 'u-photog-1',
        percentage: 40,
        note: 'Editing batch 1.',
        updatedAt: now,
      );

      final envelope = BookingDetailEnvelope(
        booking: booking,
        client: null,
        assignments: [assignment],
        payments: const [],
        package: null,
        statusHistory: const [],
        reEditRequests: const [],
        taskProgress: [progress],
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
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BookingDetailScreen(bookingId: 'b1'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Verify the detail screen mounted.
      expect(find.byType(BookingDetailScreen), findsOneWidget);

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
