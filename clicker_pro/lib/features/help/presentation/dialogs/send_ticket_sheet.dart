// lib/features/help/presentation/dialogs/send_ticket_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/support_providers.dart';
import '../../domain/support_ticket_draft.dart';
import '../../../../theme/app_theme.dart';

class SendTicketSheet extends ConsumerStatefulWidget {
  const SendTicketSheet._();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const SendTicketSheet._(),
      ),
    );
  }

  @override
  ConsumerState<SendTicketSheet> createState() => _SendTicketSheetState();
}

class _SendTicketSheetState extends ConsumerState<SendTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtl = TextEditingController();
  final _messageCtl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final draft = SupportTicketDraft(
      subject: _subjectCtl.text.trim(),
      message: _messageCtl.text.trim(),
    );
    try {
      await ref.read(supportRepositoryProvider).submitTicket(draft);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.help_ticket_send_failed)));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
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
                loc.help_send_ticket,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtl,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.help_ticket_subject),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.help_ticket_validation_subject
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtl,
                maxLines: 4,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.help_ticket_message),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.help_ticket_validation_message
                    : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _sending
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        loc.help_ticket_cancel,
                        style: TextStyle(color: AppColors.filmDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _sending ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const LensLoader(size: 18)
                          : Text(loc.help_ticket_send),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.filmDim),
    filled: true,
    fillColor: AppColors.voidElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.orange),
    ),
  );
}
