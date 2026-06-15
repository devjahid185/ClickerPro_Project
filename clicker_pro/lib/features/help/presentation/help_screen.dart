// lib/features/help/presentation/help_screen.dart
//
// Help & Support — FAQ list (collapsible cards) + contact card with
// "Send a ticket" CTA।  FAQ endpoint is public (no auth)।  Submitting a
// ticket requires auth — backend's `authenticate` middleware will 401
// guests, which the dialog surfaces as a SnackBar।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/support_providers.dart';
import 'dialogs/send_ticket_sheet.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  Future<void> _openTicketSheet(BuildContext context) async {
    final ok = await SendTicketSheet.show(context);
    if (ok == true && context.mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.help_ticket_sent)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final faqs = ref.watch(faqsProvider);

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
          loc.help_title,
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
        onRefresh: () async {
          ref.invalidate(faqsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Contact card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orangeGlow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.help_contact_section,
                          style: TextStyle(
                            color: AppColors.film,
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.help_contact_subtitle,
                    style: TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    loc.help_contact_email,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openTicketSheet(context),
                      icon: const Icon(Icons.mail_outline),
                      label: Text(loc.help_send_ticket),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── FAQ section header ────────────────────────────────
            Text(
              loc.help_faq_section.toUpperCase(),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // ── FAQ list ──────────────────────────────────────────
            faqs.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => ErrorState(
                message: loc.help_faq_load_failed,
                onRetry: () => ref.invalidate(faqsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      loc.help_faq_empty,
                      style: TextStyle(
                        color: AppColors.filmDim,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final faq in items)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          collapsedShape: const RoundedRectangleBorder(),
                          shape: const RoundedRectangleBorder(),
                          iconColor: AppColors.gold,
                          collapsedIconColor: AppColors.filmDim,
                          title: Text(
                            faq.question,
                            style: TextStyle(
                              color: AppColors.film,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq.answer,
                                style: TextStyle(
                                  color: AppColors.filmDim,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
