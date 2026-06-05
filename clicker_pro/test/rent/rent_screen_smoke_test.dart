// test/rent/rent_screen_smoke_test.dart

import 'package:clicker_pro/features/rent/application/rent_providers.dart';
import 'package:clicker_pro/features/rent/domain/rent_record.dart';
import 'package:clicker_pro/features/rent/domain/rent_repository.dart';
import 'package:clicker_pro/features/rent/presentation/rent_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRentRepo implements RentRepository {
  _FakeRentRepo({this.items = const <RentRecord>[]});

  List<RentRecord> items;
  final List<({String id, RentStatus status, DateTime? at})> updates = [];

  @override
  Future<List<RentRecord>> history() async => List.of(items);

  @override
  Future<RentRecord> create(RentRecord draft) async => draft;

  @override
  Future<void> updateStatus({
    required String id,
    required RentStatus status,
    DateTime? actualReturnDate,
  }) async {
    updates.add((id: id, status: status, at: actualReturnDate));
  }
}

Future<void> _pump(WidgetTester tester, {required RentRepository repo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [rentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RentScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders empty state when no records', (tester) async {
    await _pump(tester, repo: _FakeRentRepo());
    expect(find.text('Rent'), findsOneWidget);
    expect(find.textContaining('No rent records yet'), findsOneWidget);
  });

  testWidgets('renders rows + active count badge', (tester) async {
    final repo = _FakeRentRepo(
      items: [
        RentRecord(
          id: 'r1',
          direction: RentDirection.out_,
          counterpartyName: 'Friend Studio',
          amount: 1500,
          returnBy: DateTime.now().add(const Duration(days: 7)),
          status: RentStatus.active,
          gearName: 'Sony A7',
        ),
        RentRecord(
          id: 'r2',
          direction: RentDirection.in_,
          counterpartyName: 'Vendor X',
          amount: 800,
          status: RentStatus.returned,
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(find.text('Friend Studio'), findsOneWidget);
    expect(find.text('Vendor X'), findsOneWidget);
    expect(find.text('Sony A7'), findsOneWidget);
    // Active badge: "1 open rental"
    expect(find.textContaining('1 open rental'), findsOneWidget);
    // FAB visible
    expect(find.text('Add'), findsOneWidget);
    // Status chips (uppercase)
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('RETURNED'), findsOneWidget);
  });

  testWidgets('Mark returned button calls updateStatus', (tester) async {
    final repo = _FakeRentRepo(
      items: [
        RentRecord(
          id: 'r1',
          direction: RentDirection.out_,
          counterpartyName: 'Friend Studio',
          amount: 1500,
          status: RentStatus.active,
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(repo.updates, isEmpty);
    await tester.tap(find.text('Mark returned'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.updates, hasLength(1));
    expect(repo.updates.first.id, 'r1');
    expect(repo.updates.first.status, RentStatus.returned);
    expect(repo.updates.first.at, isNotNull);
  });
}
