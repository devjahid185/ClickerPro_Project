import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pdf/pdf_export.dart';
import '../../../core/providers.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../data/petty_cash_repository.dart';
import '../domain/petty_cash_entry.dart';

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
    final created = await _repo.create(entry);
    final current = state.valueOrNull ?? <PettyCashEntry>[];
    final next = <PettyCashEntry>[created, ...current];
    state = AsyncData(next);
    await _repo.saveCache(next);
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
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
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Petty Cash Book',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.gold,
            ),
            onPressed: () => _exportPdf(context, entries, balance),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: AppColors.glassCardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppColors.iconWrapDecoration(
                    AppColors.teal.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening Balance',
                      style: TextStyle(
                        color: AppColors.filmDim.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balance.toStringAsFixed(2),
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _PettyCashRow(
                        entry: items[i],
                        onDelete: () => ref
                            .read(pettyCashListProvider.notifier)
                            .remove(items[i].id),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Entry',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showAddSheet(context, ref),
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
                      fontFamily: 'Poppins',
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
                        borderSide: BorderSide(color: AppColors.teal),
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
                        borderSide: BorderSide(color: AppColors.teal),
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
                          selectedColor: AppColors.teal,
                          backgroundColor: AppColors.voidElevated,
                          labelStyle: TextStyle(
                            color: category == c
                                ? Colors.white
                                : AppColors.filmDim,
                          ),
                          side: BorderSide(
                            color: category == c
                                ? AppColors.teal
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
                        backgroundColor: AppColors.teal,
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

class _PettyCashRow extends StatelessWidget {
  const _PettyCashRow({required this.entry, required this.onDelete});

  final PettyCashEntry entry;
  final VoidCallback onDelete;

  Color _catColor() {
    switch (entry.category) {
      case PettyCashCategory.transport:
        return AppColors.teal;
      case PettyCashCategory.food:
        return AppColors.gold;
      case PettyCashCategory.print:
        return AppColors.purple;
      case PettyCashCategory.phone:
        return AppColors.green;
      case PettyCashCategory.misc:
        return AppColors.filmDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor();
    final dateStr =
        '${entry.date.day.toString().padLeft(2, '0')}/'
        '${entry.date.month.toString().padLeft(2, '0')}/'
        '${entry.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: AppColors.iconWrapDecoration(
            catColor.withValues(alpha: 0.15),
          ),
          child: Icon(Icons.receipt_outlined, color: catColor, size: 20),
        ),
        title: Text(
          entry.title,
          style: TextStyle(
            color: AppColors.film,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${entry.category.name} \u00b7 $dateStr',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.amount.toStringAsFixed(2),
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.filmMuted,
                size: 18,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
