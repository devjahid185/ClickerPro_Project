import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

import '../../auth/application/session_controller.dart';
import '../domain/waitlist_entry.dart';
import '../data/waitlist_api.dart';

final waitlistApiProvider = Provider<WaitlistApi>(
  (ref) => WaitlistApi(ref.read(apiClientProvider)),
);

final waitlistProvider = FutureProvider<List<WaitlistEntry>>(
  (ref) async => ref.read(waitlistApiProvider).list(),
);

class WaitlistScreen extends ConsumerWidget {
  const WaitlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(waitlistProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Waitlist',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(waitlistProvider);
        },
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (_, _) => Center(
            child: ErrorState(
              message: 'Failed to load waitlist',
              onRetry: () => ref.invalidate(waitlistProvider),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.hourglass_empty_outlined,
                    message: 'No waitlist entries',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  StaggeredList.item(i, _WaitlistRow(entry: items[i])),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddSheet(context, ref),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime preferredDate = DateTime.now().add(const Duration(days: 7));

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.filmDim),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.line(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.line(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.orange, width: 1.5),
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    'Add to Waitlist',
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.03,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Client name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Phone'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: preferredDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 730),
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => preferredDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: deco('Preferred date'),
                      child: Text(
                        '${preferredDate.year}-'
                        '${preferredDate.month.toString().padLeft(2, '0')}-'
                        '${preferredDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.film),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Note (optional)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) return;
                        final ownerId =
                            ref.read(sessionControllerProvider).value?.user.id ??
                            '';
                        final entry = WaitlistEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          ownerId: ownerId,
                          clientName: name,
                          phone: phone,
                          preferredDate: preferredDate,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        try {
                          await ref.read(waitlistApiProvider).create(entry);
                          ref.invalidate(waitlistProvider);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (e) {
                          if (ctx.mounted) {
                            final reason =
                                e is ApiException ? e.message : e.toString();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Could not save: $reason'),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
      nameCtrl.dispose();
      phoneCtrl.dispose();
      noteCtrl.dispose();
    });
  }
}

class _WaitlistRow extends StatelessWidget {
  const _WaitlistRow({required this.entry});

  final WaitlistEntry entry;

  Color _statusColor() {
    switch (entry.status) {
      case WaitlistStatus.waiting:
        return AppColors.gold;
      case WaitlistStatus.contacted:
        return AppColors.orange;
      case WaitlistStatus.booked:
        return AppColors.green;
      case WaitlistStatus.expired:
        return AppColors.filmMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final dateStr =
        '${entry.preferredDate.year}-'
        '${entry.preferredDate.month.toString().padLeft(2, '0')}-'
        '${entry.preferredDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: AppColors.iconWrapDecoration(
            statusColor.withValues(alpha: 0.14),
          ),
          child: Icon(Icons.person_outline, color: statusColor, size: 20),
        ),
        title: Text(
          entry.clientName,
          style: TextStyle(
            color: AppColors.film,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${entry.phone} \u00b7 $dateStr',
          style: TextStyle(
            color: AppColors.filmDim,
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            entry.status.name.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontFamily: AppText.monoFontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
