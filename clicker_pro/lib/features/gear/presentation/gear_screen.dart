// lib/features/gear/presentation/gear_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/booking_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/gear_providers.dart';
import 'dialogs/add_gear_sheet.dart';
import 'widgets/gear_row.dart';

class GearScreen extends ConsumerWidget {
  const GearScreen({super.key});

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: Text(
          loc.gear_delete_confirm_title,
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          loc.gear_delete_confirm_subtitle,
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.gear_cancel,
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.gear_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(gearListControllerProvider.notifier).remove(id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.gear_delete_failed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(gearListControllerProvider);
    final total = ref.watch(totalGearValueProvider);

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
          loc.gear_title,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () =>
            ref.read(gearListControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.gear_total_value.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      BookingFormat.money(
                        total,
                        lang: lang,
                        bnNumerals: lang == 'bn',
                      ),
                      style: TextStyle(
                        color: AppColors.gold,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: loc.gear_load_failed,
                  onRetry: () =>
                      ref.read(gearListControllerProvider.notifier).refresh(),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message:
                          '${loc.gear_empty_title}\n${loc.gear_empty_subtitle}',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: loc.gear_add,
                      onAction: () => AddGearSheet.show(context),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => GearRow(
                    item: items[i],
                    lang: lang,
                    onDelete: () =>
                        _confirmAndDelete(context, ref, items[i].id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (items) => items.isEmpty
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                onPressed: () => AddGearSheet.show(context),
                icon: const Icon(Icons.add),
                label: Text(loc.gear_add_short),
              ),
        orElse: () => null,
      ),
    );
  }
}
