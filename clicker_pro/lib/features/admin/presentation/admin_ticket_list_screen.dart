// lib/features/admin/presentation/admin_ticket_list_screen.dart
//
// Drill-down from the Stats tab's "Open Tickets" tile. Lists all support
// tickets (SupportController::adminIndex) and lets the admin reply, which
// closes the ticket server-side (adminReply defaults status to CLOSED).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/admin_providers.dart';
import '../domain/admin_ticket.dart';

class AdminTicketListScreen extends ConsumerWidget {
  const AdminTicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        title: Text(
          'Support Tickets',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminTicketsProvider.future),
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              ErrorState(
                message: 'Failed to load tickets',
                onRetry: () => ref.invalidate(adminTicketsProvider),
              ),
            ],
          ),
          data: (tickets) => tickets.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.support_agent_outlined,
                      message: 'No support tickets.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
                ),
        ),
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  const _TicketCard({required this.ticket});
  final AdminTicket ticket;

  void _openReplySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TicketReplySheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openReplySheet(context, ref),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: TextStyle(
                        fontFamily: AppText.brandFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: AppColors.film,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: (ticket.isOpen ? AppColors.gold : AppColors.filmDim)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: ticket.isOpen ? AppColors.gold : AppColors.filmDim,
                      ),
                    ),
                  ),
                ],
              ),
              if (ticket.userName != null || ticket.userEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.userName ?? ticket.userEmail!,
                  style: TextStyle(color: AppColors.filmDim, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                ticket.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.filmDim, fontSize: 13, height: 1.4),
              ),
              if (ticket.adminReply != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Reply: ${ticket.adminReply}',
                    style: TextStyle(color: AppColors.teal, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketReplySheet extends ConsumerStatefulWidget {
  const _TicketReplySheet({required this.ticket});
  final AdminTicket ticket;

  @override
  ConsumerState<_TicketReplySheet> createState() => _TicketReplySheetState();
}

class _TicketReplySheetState extends ConsumerState<_TicketReplySheet> {
  late final TextEditingController _replyCtrl;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _replyCtrl = TextEditingController(text: widget.ticket.adminReply ?? '');
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reply = _replyCtrl.text.trim();
    if (reply.isEmpty) {
      setState(() => _error = 'Reply cannot be empty.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(adminApiProvider).replyToTicket(widget.ticket.id, reply: reply);
      ref.invalidate(adminTicketsProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not send reply — please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.ticket.subject,
              style: TextStyle(
                fontFamily: AppText.brandFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.film,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ticket.body,
              style: TextStyle(color: AppColors.filmDim, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _replyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reply'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Send Reply & Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
