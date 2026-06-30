// lib/features/rent/presentation/rent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/widgets/motion.dart';
import '../../../theme/app_colors.dart';
import '../application/rent_providers.dart';
import 'dialogs/add_rent_sheet.dart';
import 'widgets/rent_row.dart';

class RentScreen extends ConsumerWidget {
  const RentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(rentHistoryControllerProvider);
    final activeCount = ref.watch(activeRentCountProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Text(
              loc.rent_title,
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  loc.rent_active_count(activeCount),
                  style: TextStyle(
                    color: AppColors.voidBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () =>
            ref.read(rentHistoryControllerProvider.notifier).refresh(),
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: ErrorState(
                  message: loc.rent_load_failed,
                  onRetry: () => ref
                      .read(rentHistoryControllerProvider.notifier)
                      .refresh(),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: EmptyState(
                      message:
                          '${loc.rent_empty_title}\n${loc.rent_empty_subtitle}',
                      icon: Icons.swap_horiz_outlined,
                      actionLabel: loc.rent_add,
                      onAction: () => AddRentSheet.show(context),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: items.length,
              itemBuilder: (_, i) => StaggeredList.item(
                i,
                RentRow(
                  record: items[i],
                  lang: lang,
                  onMarkReturned: () async {
                    try {
                      await ref
                          .read(rentHistoryControllerProvider.notifier)
                          .markReturned(items[i].id, DateTime.now());
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.rent_save_failed)),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (items) => items.isEmpty
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                onPressed: () => AddRentSheet.show(context),
                icon: const Icon(Icons.add),
                label: Text(loc.rent_add_short),
              ),
        orElse: () => null,
      ),
    );
  }
}
