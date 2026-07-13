// lib/features/team/presentation/salary_sheet_screen.dart
//
// Owner-side staff / freelancer payout sheet. Lists every team member with
// their assignment earnings across the owner's events: events count, earned,
// paid, due. Tapping a member opens a per-event breakdown (one row per event
// they worked) where each event — or all at once — can be marked paid.
//
// Data: `staffPayoutsProvider` (GET /api/team/payouts). Settling a payout
// goes through `teamControllerProvider.markPayoutPaid`.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/pdf/pdf_export.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/domain/expense.dart';
import '../application/team_providers.dart';
import '../domain/staff_payout.dart';
import '../domain/team_member.dart';
import '../../../theme/app_theme.dart';
import 'web_payouts.dart';

class SalarySheetScreen extends ConsumerWidget {
  const SalarySheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffPayoutsProvider);

    // On wide web the WebNavShell owns the chrome; render the dedicated desktop
    // payout sheet instead of the dark mobile body. Mobile + narrow web are
    // untouched.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: WebPayouts(
          onPay: (m) => _confirmAndPay(
            context,
            ref,
            title: 'Pay ${m.name}?',
            message:
                'Mark this member\'s ${m.events} '
                '${m.events == 1 ? 'event' : 'events'} as paid.',
            settle: () => ref
                .read(teamControllerProvider.notifier)
                .markPayoutPaid(m.userId),
          ),
          onPayAll: () {
            final sheet = async.valueOrNull;
            if (sheet == null) return;
            final unpaid =
                sheet.members.where((m) => !m.isFullyPaid).toList();
            if (unpaid.isEmpty) return;
            _confirmAndPay(
              context,
              ref,
              title: 'Pay all freelancers?',
              message:
                  'Settle every outstanding payout for '
                  '${unpaid.length} '
                  '${unpaid.length == 1 ? 'member' : 'members'}.',
              settle: () async {
                for (final m in unpaid) {
                  await ref
                      .read(teamControllerProvider.notifier)
                      .markPayoutPaid(m.userId);
                }
              },
            );
          },
        ),
      );
    }

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
          'Staff Payments',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
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
            onPressed: () {
              final sheet = async.valueOrNull;
              if (sheet != null && sheet.members.isNotEmpty) {
                exportStaffPayoutsPdf(context, sheet);
              }
            },
          ),
        ],
      ),
      body: const StaffPayoutsBody(),
    );
  }

  /// Confirm-then-settle used by the web payout rows / Pay All. Settling moves
  /// real money, so it always confirms first, then surfaces success/failure.
  Future<void> _confirmAndPay(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required Future<void> Function() settle,
  }) async {
    // Capture before the dialog await so we never touch `context` post-gap.
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A18),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF7A786F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7A786F))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE2620E),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await settle();
      messenger.showSnackBar(
        const SnackBar(content: Text('Payout settled.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not settle payout.')),
      );
    }
  }
}

/// The staff/freelancer payout list — summary header, per-member cards and the
/// per-event breakdown/settle flow. Extracted from [SalarySheetScreen] so the
/// unified Payments screen can host it as its "Payouts" tab without duplicating
/// any of the mark-paid logic. Reads `staffPayoutsProvider` (GET
/// /api/team/payouts); pull-to-refresh re-fetches.
class StaffPayoutsBody extends ConsumerWidget {
  const StaffPayoutsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffPayoutsProvider);

    return RefreshIndicator(
      color: AppColors.teal,
      backgroundColor: AppColors.voidLight,
      onRefresh: () async => ref.invalidate(staffPayoutsProvider),
      child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Could not load staff payments.',
            onRetry: () => ref.invalidate(staffPayoutsProvider),
          ),
        ),
        data: (sheet) {
          if (sheet.members.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.payments_outlined,
                  message:
                      'No staff payouts yet\nAssign team members to events with a payout',
                ),
                SizedBox(height: 24),
                _OfficeStaffSalarySection(),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _SummaryHeader(sheet: sheet),
              const SizedBox(height: 20),
              _sectionHeaderText('TEAM MEMBERS'),
              const SizedBox(height: 10),
              ...sheet.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StaffPayoutCard(payout: m),
                ),
              ),
              const SizedBox(height: 20),
              const _OfficeStaffSalarySection(),
            ],
          );
        },
      ),
    );
  }
}

// ─── Office staff monthly salary ─────────────────────────────────────
//
// Lists every OFFICE_STAFF team member (editors, HR, office boys…) with a
// "Pay Salary" action. A payment is recorded as a normal Expense
// (category "Salary"), so it flows into profit and cash-flow like every
// other expense — per Heaven's spec.
class _OfficeStaffSalarySection extends ConsumerWidget {
  const _OfficeStaffSalarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider);
    final staff = (membersAsync.valueOrNull ?? const <TeamMember>[])
        .where((m) => m.role.toUpperCase() == 'OFFICE_STAFF')
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeaderText('OFFICE STAFF — MONTHLY SALARY'),
        const SizedBox(height: 10),
        if (membersAsync.isLoading && staff.isEmpty)
          const Center(child: LensLoader(size: 20))
        else if (staff.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              'No office staff in the team yet. Staff who register with '
              'the Office Staff role and join via invite code appear here.',
              style: TextStyle(color: AppColors.filmDim, fontSize: 12.5),
            ),
          )
        else
          ...staff.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OfficeStaffRow(member: m),
            ),
          ),
      ],
    );
  }
}

class _OfficeStaffRow extends ConsumerWidget {
  const _OfficeStaffRow({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.indigoSoft,
            child: Text(
              member.fullName.isNotEmpty
                  ? member.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.film,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.filmDim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _PaySalaryDialog.show(context, ref, member),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Pay Salary', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _PaySalaryDialog {
  const _PaySalaryDialog._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final amountCtl = TextEditingController();
    final noteCtl = TextEditingController();
    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = '${monthNames[now.month - 1]} ${now.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Pay salary — ${member.fullName}',
          style: TextStyle(color: AppColors.film, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: AppColors.film),
              decoration: InputDecoration(
                labelText: 'Amount (৳) — $monthLabel',
                labelStyle: TextStyle(color: AppColors.filmDim),
              ),
            ),
            TextField(
              controller: noteCtl,
              style: TextStyle(color: AppColors.film),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: TextStyle(color: AppColors.filmDim),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    final amount = double.tryParse(amountCtl.text.trim()) ?? 0;
    if (confirmed != true || amount <= 0) {
      amountCtl.dispose();
      noteCtl.dispose();
      return;
    }

    final extraNote = noteCtl.text.trim();
    final localId =
        'local_${DateTime.now().microsecondsSinceEpoch}_salary';
    final draft = Expense(
      id: localId,
      category: 'Salary',
      amount: amount,
      note: [
        'Salary — ${member.fullName} — $monthLabel',
        if (extraNote.isNotEmpty) extraNote,
      ].join(' · '),
      incurredAt: DateTime.now(),
    );
    amountCtl.dispose();
    noteCtl.dispose();

    try {
      await ref.read(expenseListControllerProvider.notifier).add(draft);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Salary recorded as expense — ${member.fullName} ($monthLabel)',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not record salary: $e')));
    }
  }
}

String _money(double v) =>
    BookingFormat.money(v, lang: 'en', bnNumerals: false);

Widget _sectionHeaderText(String title) {
  return Text(
    title,
    style: TextStyle(
      fontFamily: AppText.brandFontFamily,
      fontSize: 12,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: AppColors.filmMuted,
    ),
  );
}

/// Shares the staff-payout sheet as a PDF. Public so both the standalone
/// [SalarySheetScreen] app-bar action and the Payments screen can call it.
Future<void> exportStaffPayoutsPdf(
  BuildContext context,
  StaffPayoutSheet sheet,
) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PdfExporter.share(
        PdfDocumentData(
          documentTitle: 'Staff Payments',
          fileName: 'staff_payments',
          subtitle: '${sheet.members.length} members',
          summary: [
            PdfRow('Total earned', _money(sheet.totalEarned)),
            PdfRow('Total paid', _money(sheet.totalPaid)),
            PdfRow('Total due', _money(sheet.totalDue), emphasize: true),
          ],
          table: PdfTable(
            headers: const ['Member', 'Events', 'Earned', 'Paid', 'Due'],
            rows: [
              for (final m in sheet.members)
                [
                  m.name,
                  m.events.toString(),
                  _money(m.earned),
                  _money(m.paid),
                  _money(m.due),
                ],
            ],
          ),
          footnote: 'Generated by Graphy7',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not create PDF: $e',
            style: TextStyle(color: AppColors.film),
          ),
          backgroundColor: AppColors.voidElevated,
        ),
      );
    }
  }

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.sheet});
  final StaffPayoutSheet sheet;

  @override
  Widget build(BuildContext context) {
    String m(double v) => BookingFormat.money(v, lang: 'en', bnNumerals: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _stat('EARNED', m(sheet.totalEarned), AppColors.gold),
          const SizedBox(width: 16),
          _stat('PAID', m(sheet.totalPaid), AppColors.green),
          const SizedBox(width: 16),
          _stat('DUE', m(sheet.totalDue), AppColors.coral),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 9,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// One member's payout summary. Tapping opens the per-event breakdown sheet.
class _StaffPayoutCard extends ConsumerWidget {
  const _StaffPayoutCard({required this.payout});
  final StaffPayout payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = payout.isFullyPaid;
    final statusColor = isPaid ? AppColors.green : AppColors.coral;
    String m(double v) => BookingFormat.money(v, lang: 'en', bnNumerals: false);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showBreakdown(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                  backgroundImage:
                      (payout.avatar != null && payout.avatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(payout.avatar!)
                      : null,
                  child: (payout.avatar == null || payout.avatar!.isEmpty)
                      ? Text(
                          payout.name.isNotEmpty
                              ? payout.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payout.name,
                        style: TextStyle(
                          fontFamily: AppText.brandFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.film,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${payout.events} ${payout.events == 1 ? 'event' : 'events'} · tap for breakdown',
                        style: TextStyle(
                          fontFamily: AppText.brandFontFamily,
                          fontSize: 11,
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'DUE',
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.line(0.06)),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric('Earned', m(payout.earned), AppColors.gold),
                const SizedBox(width: 16),
                _metric('Paid', m(payout.paid), AppColors.green),
                const Spacer(),
                if (!isPaid) _metric('Due', m(payout.due), AppColors.coral),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: AppColors.filmMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showBreakdown(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PayoutBreakdownSheet(userId: payout.userId),
    );
  }
}

/// Per-event payout breakdown for one member, with per-event and "pay all"
/// settle actions. Reads live data so it reflects mark-paid immediately.
class _PayoutBreakdownSheet extends ConsumerWidget {
  const _PayoutBreakdownSheet({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffPayoutsProvider);
    final payout = async.valueOrNull?.members
        .where((m) => m.userId == userId)
        .firstOrNull;

    String m(double v) => BookingFormat.money(v, lang: 'en', bnNumerals: false);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: payout == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: LensLoader()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.filmDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    payout.name,
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${m(payout.due)} of ${m(payout.earned)}',
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: payout.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PayoutItemRow(
                        userId: userId,
                        item: payout.items[i],
                      ),
                    ),
                  ),
                  if (!payout.isFullyPaid) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text('Pay all due · ${m(payout.due)}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: AppColors.voidBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _pay(context, ref),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref, {
    String? assignmentId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(teamControllerProvider.notifier)
          .markPayoutPaid(userId, assignmentId: assignmentId);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Payment recorded ✓'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      // Show the real reason — the generic message hid the server error.
      final reason = e is ApiException ? e.message : e.toString();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not record payment: $reason',
            style: TextStyle(color: AppColors.film),
          ),
          backgroundColor: AppColors.voidElevated,
        ),
      );
    }
  }
}

class _PayoutItemRow extends ConsumerWidget {
  const _PayoutItemRow({required this.userId, required this.item});
  final String userId;
  final PayoutItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = item.date == null
        ? ''
        : BookingFormat.dateOnly(item.date!, lang: 'en');
    String m(double v) => BookingFormat.money(v, lang: 'en', bnNumerals: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.voidBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.role.isNotEmpty) _titleCase(item.role),
                    if (dateStr.isNotEmpty) dateStr,
                  ].join(' · '),
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.7),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            m(item.amount),
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          if (item.paid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PAID',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            )
          else
            _PayButton(
              onTap: () => ref
                  .read(teamControllerProvider.notifier)
                  .markPayoutPaid(userId, assignmentId: item.assignmentId),
            ),
        ],
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await onTap();
        } catch (e) {
          final reason = e is ApiException ? e.message : e.toString();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Could not record payment: $reason',
                style: TextStyle(color: AppColors.film),
              ),
              backgroundColor: AppColors.voidElevated,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Pay',
          style: TextStyle(
            color: AppColors.teal,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
