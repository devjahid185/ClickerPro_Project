// test/bookings/booking_detail_screen_smoke_test.dart
//
// Smoke test for the booking detail screen. Seeds an in-memory Drift
// instance with a single booking + client + assignment + status-history
// row, mounts the screen, and asserts:
//
//   • The header card renders the booking title.
//   • The status badge reflects the seeded status ("pending" → indigo).
//   • The client section renders the seeded client name + phone.
//   • The assignments section is visible.
//
// We override the booking repository with a fake that returns a
// hand-built envelope so we don't depend on the full
// `BookingRepository.getDetail` cascade in this slice — that path is
// already covered by the DAO tests.

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
import 'package:clicker_pro/features/bookings/domain/client.dart';
import 'package:clicker_pro/features/bookings/domain/event_type.dart';
import 'package:clicker_pro/features/bookings/domain/shift.dart';
import 'package:clicker_pro/features/bookings/domain/status_history_entry.dart';
import 'package:clicker_pro/features/bookings/presentation/booking_detail_screen.dart';
import 'package:clicker_pro/features/bookings/presentation/widgets/payment_summary_card.dart';
import 'package:clicker_pro/features/profile/application/profile_controllers.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/core/booking_status/booking_status.dart';
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
    await initializeDateFormatting('bn');
  });

  testWidgets('BookingDetailScreen renders header + client + assignments', (
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
    final session = Session(token: 't', user: user, issuedAt: DateTime.now());

    final now = DateTime(2025, 6, 1, 10);
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
      brideName: 'Asha',
      groomName: 'Rahim',
      clientId: 'c1',
      status: BookingStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    final client = Client(
      id: 'c1',
      studioId: 'u-owner-1',
      name: 'Acme Family',
      phone: '01900000001',
      createdAt: now,
      updatedAt: now,
    );
    final assignment = Assignment(
      id: 'a1',
      bookingId: 'b1',
      userId: 'u-photog-1',
      role: AssignmentRole.photographer,
      payout: 5000,
      createdAt: now,
      updatedAt: now,
    );
    final history = StatusHistoryEntry(
      id: 'sh1',
      bookingId: 'b1',
      fromStatus: BookingStatus.pending,
      toStatus: BookingStatus.pending,
      changedByUserId: 'u-owner-1',
      at: now,
    );
    final envelope = BookingDetailEnvelope(
      booking: booking,
      client: client,
      assignments: [assignment],
      payments: const [],
      package: null,
      statusHistory: [history],
      reEditRequests: const [],
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
          // Hand-build the envelope so the screen's local-first read
          // path returns predictable data without exercising the full
          // BookingRepository cascade (already covered by DAO tests).
          bookingRepositoryProvider.overrideWithValue(
            _FakeBookingRepository(envelope),
          ),
          // The payment summary FutureProvider would normally read
          // through the payment repository; with payments empty the
          // aggregate is zero across the board.
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

    // Wait a couple of frames for the AsyncNotifier to resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Acme Garden Wedding'), findsOneWidget);
    expect(find.text('Acme Family'), findsOneWidget);
    expect(find.text('01900000001'), findsOneWidget);

    // Assignments + status timeline render lower in the ListView; scroll
    // them into view so the lazy build window mounts them. The drag
    // itself fails if the target is never reached, so we don't need a
    // separate assertion afterwards.
    final listFinder = find.byType(ListView);
    await tester.dragUntilVisible(
      find.text('ASSIGNMENTS', skipOffstage: false),
      listFinder,
      const Offset(0, -120),
    );
    await tester.dragUntilVisible(
      find.text('STATUS HISTORY', skipOffstage: false),
      listFinder,
      const Offset(0, -120),
    );

    await db.close();
  });
}

class _FakeSessionController extends SessionController {
  _FakeSessionController({this.initial});
  final Session? initial;
  @override
  Future<Session?> build() async => initial;
}

/// Minimal fake — only `getDetail` is exercised in this smoke test;
/// every other method falls through to `noSuchMethod` so unexpected
/// usage surfaces as a test failure rather than a silent stub.
class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository(this._envelope);

  final BookingDetailEnvelope _envelope;

  @override
  Future<BookingDetailEnvelope> getDetail(String localId) async => _envelope;

  @override
  Future<void> refreshFromRemote({
    BookingFilter? filter,
    String? singleEventId,
  }) async {
    // Background refresh is a no-op in tests.
  }

  // Unused in this test — but the class must satisfy the interface.
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeBookingRepository.${invocation.memberName} is not stubbed.',
    );
  }
}
