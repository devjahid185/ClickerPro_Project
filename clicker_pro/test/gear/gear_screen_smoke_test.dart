// test/gear/gear_screen_smoke_test.dart

import 'package:clicker_pro/features/gear/application/gear_providers.dart';
import 'package:clicker_pro/features/gear/domain/gear_item.dart';
import 'package:clicker_pro/features/gear/domain/gear_repository.dart';
import 'package:clicker_pro/features/gear/presentation/gear_screen.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGearRepo implements GearRepository {
  _FakeGearRepo({this.items = const <GearItem>[]});

  List<GearItem> items;

  @override
  Future<List<GearItem>> list() async => List.of(items);

  @override
  Future<GearItem> add(GearItem draft) async => draft.copyWithId('new-1');

  @override
  Future<void> remove(String id) async {
    items = items.where((g) => g.id != id).toList();
  }
}

extension on GearItem {
  GearItem copyWithId(String id) => GearItem(
    id: id,
    name: name,
    brand: brand,
    category: category,
    condition: condition,
    value: value,
  );
}

Future<void> _pump(WidgetTester tester, {required GearRepository repo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gearRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GearScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders empty state when no gear', (tester) async {
    final repo = _FakeGearRepo();
    await _pump(tester, repo: repo);

    expect(find.text('Gear'), findsOneWidget);
    expect(find.textContaining('No gear yet'), findsOneWidget);
    // Total value card shows 0
    expect(find.text('TOTAL KIT VALUE'), findsOneWidget);
  });

  testWidgets('renders rows + FAB when gear exists', (tester) async {
    final repo = _FakeGearRepo(
      items: [
        const GearItem(
          id: 'g1',
          name: 'Sony A7 IV',
          brand: 'Sony',
          category: 'Camera',
          condition: 'Good',
          value: 250000,
        ),
        const GearItem(
          id: 'g2',
          name: '50mm f/1.8',
          brand: 'Sony',
          category: 'Lens',
          value: 35000,
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(find.text('Sony A7 IV'), findsOneWidget);
    expect(find.text('50mm f/1.8'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget); // FAB
  });
}
