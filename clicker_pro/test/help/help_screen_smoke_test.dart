// test/help/help_screen_smoke_test.dart

import 'package:clicker_pro/features/help/application/support_providers.dart';
import 'package:clicker_pro/features/help/domain/faq_entry.dart';
import 'package:clicker_pro/features/help/domain/support_repository.dart';
import 'package:clicker_pro/features/help/domain/support_ticket_draft.dart';
import 'package:clicker_pro/features/help/presentation/help_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupportRepo implements SupportRepository {
  _FakeSupportRepo({this.items = const <FaqEntry>[]});

  List<FaqEntry> items;

  @override
  Future<List<FaqEntry>> faqs() async => List.of(items);

  @override
  Future<String> submitTicket(SupportTicketDraft draft) async => 'tkt-1';
}

Future<void> _pump(
  WidgetTester tester, {
  required SupportRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportRepositoryProvider.overrideWithValue(repo),
        // Bypass the network-backed contact lookup so the smoke test doesn't
        // leave a retry timer pending; the UI falls back to these anyway.
        supportContactProvider.overrideWith((ref) async => supportContactFallback),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HelpScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders contact card + FAQ section header', (tester) async {
    await _pump(tester, repo: _FakeSupportRepo());

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Need more help?'), findsOneWidget);
    expect(find.text('Send a ticket'), findsOneWidget);
    expect(find.text('FREQUENTLY ASKED'), findsOneWidget);
    expect(find.textContaining('No FAQs published'), findsOneWidget);
  });

  testWidgets('renders FAQ rows expanded on tap', (tester) async {
    final repo = _FakeSupportRepo(
      items: const [
        FaqEntry(
          id: 'f1',
          question: 'How do I add a booking?',
          answer: 'Tap the + button on the bookings screen.',
          category: 'General',
          order: 1,
        ),
        FaqEntry(
          id: 'f2',
          question: 'How do I export data?',
          answer: 'Settings → Account → Export.',
          category: 'Account',
          order: 2,
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(find.text('How do I add a booking?'), findsOneWidget);
    expect(find.text('How do I export data?'), findsOneWidget);
    // Answer hidden until tap
    expect(find.textContaining('Tap the + button'), findsNothing);

    await tester.tap(find.text('How do I add a booking?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap the + button'), findsOneWidget);
  });
}
