// lib/features/help/presentation/help_screen.dart
//
// Help & Support — FAQ list (collapsible cards) + contact card with
// "Send a ticket" CTA।  FAQ endpoint is public (no auth)।  Submitting a
// ticket requires auth — backend's `authenticate` middleware will 401
// guests, which the dialog surfaces as a SnackBar।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../whatsapp/data/whatsapp_service.dart';
import '../application/support_providers.dart';
import 'dialogs/send_ticket_sheet.dart';
import '../../../theme/app_theme.dart';

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

  Future<void> _emailUs(BuildContext context, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('Graphy7 Support')}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _toast(context, AppLocalizations.of(context).help_no_mail_app);
    }
  }

  /// Opens a WhatsApp chat with the admin-configured support number. The
  /// number itself is never shown in the UI — the user just lands in a chat
  /// with a pre-filled message addressed to the app.
  Future<void> _whatsAppUs(BuildContext context, String number) async {
    final ok = await WhatsAppService.openChat(
      phone: number,
      message: 'Graphy7 Support: ',
    );
    if (!ok && context.mounted) {
      _toast(context, AppLocalizations.of(context).help_no_whatsapp);
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final faqs = ref.watch(faqsProvider);
    final contact = ref
        .watch(supportContactProvider)
        .valueOrNull ?? supportContactFallback;

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
            fontFamily: AppText.brandFontFamily,
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
                        child: Icon(
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
                            fontFamily: AppText.brandFontFamily,
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
                  const SizedBox(height: 14),

                  // Email — tap to open the mail app with a pre-filled subject.
                  _ContactAction(
                    icon: Icons.mail_outline_rounded,
                    label: loc.help_email_us,
                    value: contact.email,
                    onTap: () => _emailUs(context, contact.email),
                  ),

                  // WhatsApp — only shown when the admin has set a number. The
                  // number is never displayed; the row just says "app name".
                  if (contact.whatsapp.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ContactAction(
                      icon: Icons.chat_rounded,
                      label: loc.help_whatsapp_us,
                      value: 'Graphy7',
                      onTap: () => _whatsAppUs(context, contact.whatsapp),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openTicketSheet(context),
                      icon: const Icon(Icons.confirmation_number_outlined),
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
              style: TextStyle(
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

/// A tappable contact row (icon + label + secondary value) used for the email
/// and WhatsApp channels on the Help screen.
class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (value.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.filmDim,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
