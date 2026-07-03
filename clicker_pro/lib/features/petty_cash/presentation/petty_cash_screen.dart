import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/pdf/pdf_export.dart';
import '../../../core/providers.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_colors.dart';
import '../data/petty_cash_repository.dart';
import '../domain/petty_cash_entry.dart';
import '../../../theme/app_theme.dart';

/// Money in the app's Bangladeshi grouping, e.g. "৳4,250".
String _money(double v) =>
    '৳${NumberFormat('#,##,##0', 'en_IN').format(v.round())}';

/// Category → (icon, soft bg, saturated fg) for the expense rows, matching
/// the .dc.html MOD-54 colour coding.
({IconData icon, Color bg, Color fg}) _catStyle(PettyCashCategory c) {
  switch (c) {
    case PettyCashCategory.transport:
      return (
        icon: Icons.local_taxi_rounded,
        bg: AppColors.purpleSoft,
        fg: AppColors.purple,
      );
    case PettyCashCategory.food:
      return (
        icon: Icons.restaurant_rounded,
        bg: AppColors.orangeSoft,
        fg: AppColors.primary700,
      );
    case PettyCashCategory.print:
      return (
        icon: Icons.print_rounded,
        bg: AppColors.greenSoft,
        fg: AppColors.green,
      );
    case PettyCashCategory.phone:
      return (
        icon: Icons.phone_iphone_rounded,
        bg: AppColors.goldSoft,
        fg: AppColors.gold,
      );
    case PettyCashCategory.misc:
      return (
        icon: Icons.category_rounded,
        bg: AppColors.line(0.05),
        fg: AppColors.filmDim,
      );
  }
}

// ─── Petty Cash Notifier ─────────────────────────────────────────────────────
//
// API-backed (GET/POST/DELETE /api/petty-cash) with a SharedPreferences cache
// so the list still renders offline. On load we try the server first and fall
// back to cache; mutations hit the server then refresh the cache.

final pettyCashRepositoryProvider = Provider<PettyCashRepository>(
  (ref) => PettyCashRepository(ref.read(apiClientProvider)),
);

class _PettyCashNotifier extends AsyncNotifier<List<PettyCashEntry>> {
  PettyCashRepository get _repo => ref.read(pettyCashRepositoryProvider);

  @override
  Future<List<PettyCashEntry>> build() => _repo.list();

  Future<void> add(PettyCashEntry entry) async {
    // Offline-first: try the server, but if it's unreachable keep the
    // locally-built entry (it already carries a generated id) so the money
    // is still recorded and cached. Without this fallback an offline backend
    // made every "Save" silently lose the entry.
    PettyCashEntry created;
    try {
      created = await _repo.create(entry);
    } catch (_) {
      created = entry;
    }
    final current = state.valueOrNull ?? <PettyCashEntry>[];
    final next = <PettyCashEntry>[created, ...current];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }

  Future<void> remove(String id) async {
    // Same offline-first stance as add(): a failed server delete must not
    // block removing the row locally.
    try {
      await _repo.delete(id);
    } catch (_) {
      // Offline — drop it locally; the cache below becomes the source of truth.
    }
    final current = state.valueOrNull ?? <PettyCashEntry>[];
    final next = <PettyCashEntry>[for (final e in current) if (e.id != id) e];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }
}

final pettyCashListProvider =
    AsyncNotifierProvider<_PettyCashNotifier, List<PettyCashEntry>>(
      _PettyCashNotifier.new,
    );

final pettyCashBalanceProvider = Provider<double>((ref) {
  final entries = ref.watch(pettyCashListProvider).valueOrNull ?? [];
  return entries.fold<double>(0, (sum, e) => sum + e.amount);
});

class PettyCashScreen extends ConsumerWidget {
  const PettyCashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pettyCashListProvider);
    final entries = async.valueOrNull ?? [];
    final balance = ref.watch(pettyCashBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Petty Cash',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.film),
            onPressed: () => _exportPdf(context, entries, balance),
          ),
        ],
      ),
      body: Column(
        children: [
          _BalanceCard(spent: balance, count: entries.length),
          Expanded(
            child: async.when(
              loading: () => const Center(child: LensLoader()),
              error: (_, _) => const Center(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Could not load entries.',
                ),
              ),
              data: (items) => items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'No petty cash entries',
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                      itemCount: items.length,
                      itemBuilder: (_, i) => StaggeredList.item(
                        i,
                        _PettyCashRow(
                          entry: items[i],
                          onDelete: () => ref
                              .read(pettyCashListProvider.notifier)
                              .remove(items[i].id),
                        ),
                      ),
                    ),
            ),
          ),
          // Inline "Add Expense" bar (.dc.html) — replaces the floating FAB.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showAddSheet(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<PettyCashEntry> entries,
    double balance,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    String d(DateTime t) =>
        '${t.day.toString().padLeft(2, '0')}/'
        '${t.month.toString().padLeft(2, '0')}/${t.year}';
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Petty Cash Book',
          fileName: 'petty_cash_book',
          subtitle: '${entries.length} entries',
          summary: [
            PdfRow(
              'Balance',
              '৳ ${balance.toStringAsFixed(2)}',
              emphasize: true,
            ),
          ],
          table: entries.isEmpty
              ? null
              : PdfTable(
                  headers: const ['Title', 'Category', 'Date', 'Amount'],
                  rows: [
                    for (final e in entries)
                      [
                        e.title,
                        e.category.name,
                        d(e.date),
                        '৳ ${e.amount.toStringAsFixed(2)}',
                      ],
                  ],
                ),
          footnote: 'Generated by Clicker Pro',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create PDF: $e')),
      );
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    PettyCashCategory category = PettyCashCategory.misc;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.filmMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Add Petty Cash Entry',
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: AppColors.film),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: AppColors.filmDim),
                      filled: true,
                      fillColor: AppColors.voidElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: AppColors.film),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: AppColors.filmDim),
                      filled: true,
                      fillColor: AppColors.voidElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in PettyCashCategory.values)
                        ChoiceChip(
                          label: Text(
                            c.name[0].toUpperCase() + c.name.substring(1),
                          ),
                          selected: category == c,
                          onSelected: (_) => setSheetState(() => category = c),
                          selectedColor: AppColors.orange,
                          backgroundColor: AppColors.voidElevated,
                          labelStyle: TextStyle(
                            color: category == c
                                ? AppColors.onAccent
                                : AppColors.filmDim,
                          ),
                          side: BorderSide(
                            color: category == c
                                ? AppColors.orange
                                : AppColors.glassBorder,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (title.isEmpty || amount == null || amount <= 0) {
                          return;
                        }
                        final entry = PettyCashEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          category: category,
                          amount: amount,
                          date: DateTime.now(),
                        );
                        ref
                            .read(pettyCashListProvider.notifier)
                            .add(entry);
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose the sheet's controllers once it closes to avoid a leak.
      titleCtrl.dispose();
      amountCtrl.dispose();
    });
  }
}

/// Dark "PETTY CASH BALANCE" hero (.dc.html MOD-54): mono label, big figure,
/// a bleeding orange corner glow, and a SPENT / ENTRIES stat row.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.spent, required this.count});

  final double spent;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.film,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PETTY CASH SPENT',
                    style: TextStyle(
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 10,
                      letterSpacing: 1.6,
                      // Hero fills with `film`; label must invert to the surface
                      // colour to stay legible on both themes.
                      color: AppColors.surface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _money(spent),
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.03 * 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat('SPENT', _money(spent), AppColors.orangeLight),
                      const SizedBox(width: 24),
                      _stat('ENTRIES', '$count', AppColors.surface),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Soft radial bleed instead of a hard-edged ring.
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.22),
                      AppColors.orange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color valueColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.surface.withValues(alpha: 0.55),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _PettyCashRow extends StatelessWidget {
  const _PettyCashRow({required this.entry, required this.onDelete});

  final PettyCashEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = _catStyle(entry.category);
    final catLabel =
        entry.category.name[0].toUpperCase() + entry.category.name.substring(1);
    final dateStr = DateFormat('MMM d').format(entry.date);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppColors.redSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, color: style.fg, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    catLabel,
                    style: TextStyle(
                      color: AppColors.filmMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(entry.amount),
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
