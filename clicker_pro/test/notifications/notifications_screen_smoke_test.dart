// test/notifications/notifications_screen_smoke_test.dart
//
// Smoke for NotificationsScreen।  Stubs the repository and asserts:
//
//   • header renders + unread badge appears with the right count
//   • category badge labels render
//   • empty state renders when the list is empty
//   • tap on an unread row triggers `markRead` exactly once

import 'package:clicker_pro/features/notifications/application/notification_providers.dart';
import 'package:clicker_pro/features/notifications/domain/app_notification.dart';
import 'package:clicker_pro/features/notifications/domain/notification_repository.dart';
import 'package:clicker_pro/features/notifications/presentation/notifications_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotifRepo implements NotificationRepository {
  _FakeNotifRepo({this.items = const <AppNotification>[]});

  List<AppNotification> items;
  final List<String> markedRead = <String>[];

  @override
  Future<List<AppNotification>> list() async => List.of(items);

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required NotificationRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NotificationsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders rows + unread badge', (tester) async {
    final repo = _FakeNotifRepo(
      items: [
        AppNotification(
          id: 'n1',
          category: 'OPERATIONS',
          message: 'New booking from Karim',
          read: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AppNotification(
          id: 'n2',
          category: 'PAYMENT',
          message: 'Advance received',
          read: true,
          sentAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(find.text('Notifications'), findsOneWidget);
    // Unread count = 1
    expect(find.text('1 unread'), findsOneWidget);
    // Category labels render
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    // Message text renders
    expect(find.text('New booking from Karim'), findsOneWidget);
  });

  testWidgets('tap on unread row marks it read', (tester) async {
    final repo = _FakeNotifRepo(
      items: [
        AppNotification(
          id: 'n1',
          category: 'REEDIT',
          message: 'Re-edit assigned',
          read: false,
          sentAt: DateTime.now(),
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(repo.markedRead, isEmpty);
    await tester.tap(find.text('Re-edit assigned'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.markedRead, equals(['n1']));
  });

  testWidgets('renders empty state when list is empty', (tester) async {
    final repo = _FakeNotifRepo(items: const <AppNotification>[]);

    await _pump(tester, repo: repo);

    expect(find.textContaining('No notifications'), findsOneWidget);
    // Unread badge should NOT render when count = 0
    expect(find.textContaining('unread'), findsNothing);
  });
}
