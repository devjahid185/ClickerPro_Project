import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/validation/phone_validator.dart';
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
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final fbCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime preferredDate = DateTime.now().add(const Duration(days: 7));
    var saving = false;

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
              child: Form(
                key: formKey,
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
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Client name'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Client name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Phone'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => PhoneValidator.validate(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fbCtrl,
                    keyboardType: TextInputType.url,
                    style: TextStyle(color: AppColors.film),
                    decoration: deco('Facebook link (optional)'),
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
                      onPressed: saving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setSheetState(() => saving = true);
                              final ownerId = ref
                                      .read(sessionControllerProvider)
                                      .value
                                      ?.user
                                      .id ??
                                  '';
                              final entry = WaitlistEntry(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                ownerId: ownerId,
                                clientName: nameCtrl.text.trim(),
                                phone: PhoneValidator.normalize(
                                  phoneCtrl.text,
                                ),
                                preferredDate: preferredDate,
                                note: noteCtrl.text.trim().isEmpty
                                    ? null
                                    : noteCtrl.text.trim(),
                                facebookLink: fbCtrl.text.trim().isEmpty
                                    ? null
                                    : fbCtrl.text.trim(),
                              );
                              try {
                                await ref
                                    .read(waitlistApiProvider)
                                    .create(entry);
                                ref.invalidate(waitlistProvider);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() => saving = false);
                                  final reason = e is ApiException
                                      ? e.message
                                      : e.toString();
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
                      child: saving
                          ? const LensLoader(size: 18)
                          : const Text(
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
      ),
    ).whenComplete(() {
      // Dispose the sheet's controllers once it closes to avoid a leak.
      nameCtrl.dispose();
      phoneCtrl.dispose();
      fbCtrl.dispose();
      noteCtrl.dispose();
    });
  }
}

class _WaitlistRow extends StatelessWidget {
  const _WaitlistRow({required this.entry});

  final WaitlistEntry entry;

  /// Opens the phone dialer pre-filled with the client's number. Fail-soft:
  /// a missing dialer (rare) is logged, never crashes the list.
  Future<void> _call(BuildContext context) async {
    final number = entry.phone.trim();
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the dialer')),
        );
      }
    } catch (e) {
      AppLogger.w('waitlist', 'dial failed: $e');
    }
  }

  /// Opens the client's Facebook link in the browser / Facebook app.
  Future<void> _openFacebook(BuildContext context) async {
    final raw = entry.facebookLink?.trim() ?? '';
    if (raw.isEmpty) return;
    // Accept links pasted without a scheme (e.g. "facebook.com/…").
    final normalized =
        raw.startsWith('http://') || raw.startsWith('https://')
            ? raw
            : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (e) {
      AppLogger.w('waitlist', 'facebook open failed: $e');
    }
  }

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call the client straight from the list.
            _RowActionButton(
              icon: Icons.call_outlined,
              color: AppColors.green,
              tooltip: 'Call',
              onTap: () => _call(context),
            ),
            // Facebook / Messenger \u2014 only when a link is on file.
            if ((entry.facebookLink?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(width: 4),
              _RowActionButton(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                tooltip: 'Open Facebook',
                onTap: () => _openFacebook(context),
              ),
            ],
            const SizedBox(width: 8),
            Container(
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
          ],
        ),
      ),
    );
  }
}

/// Small round tap target for the per-row call / Facebook actions.
class _RowActionButton extends StatelessWidget {
  const _RowActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}
