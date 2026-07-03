// lib/features/payments/presentation/payment_entry_screen.dart
//
// Unified Payments screen with two tabs:
//   • Receipts — money received FROM clients (advance / due / extra), recorded
//     via the PaymentEntrySheet bottom-sheet. "Client থেকে কীভাবে receive".
//   • Payouts  — money the owner owes TO staff/freelancers per assignment, with
//     a per-event breakdown and mark-paid. "কাকে কাকে payment করতে হবে".
//
// The Payouts tab reuses the existing StaffPayoutsBody (GET /api/team/payouts)
// so there is a single source of truth for the settle flow — this screen only
// adds the tab shell and PDF export around it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../team/application/team_providers.dart';
import '../../team/presentation/salary_sheet_screen.dart';
import '../application/payment_providers.dart';
import '../domain/payment_record.dart';
import 'payment_entry_sheet.dart';
import '../../../theme/app_theme.dart';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    // Rebuild on tab change so the FAB (Receipts-only) shows/hides.
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onReceipts = _tabs.index == 0;

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
          'Payments',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // PDF export is only meaningful on the Payouts (staff sheet) tab.
          if (!onReceipts)
            IconButton(
              icon: Icon(Icons.picture_as_pdf_outlined, color: AppColors.gold),
              onPressed: () {
                final sheet = ref.read(staffPayoutsProvider).valueOrNull;
                if (sheet != null && sheet.members.isNotEmpty) {
                  exportStaffPayoutsPdf(context, sheet);
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.teal,
          labelColor: AppColors.film,
          unselectedLabelColor: AppColors.filmDim,
          labelStyle: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Receipts'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      floatingActionButton: onReceipts
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Record Payment',
                style: TextStyle(
                  fontFamily: AppText.brandFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                await PaymentEntrySheet.show(context, eventId: '');
                ref.invalidate(paymentListControllerProvider);
              },
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ReceiptsTab(),
          StaffPayoutsBody(),
        ],
      ),
    );
  }
}

/// Client receipts tab — the recorded payments list with a running total.
class _ReceiptsTab extends ConsumerWidget {
  const _ReceiptsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentListControllerProvider);

    return RefreshIndicator(
      color: AppColors.teal,
      backgroundColor: AppColors.voidLight,
      onRefresh: () =>
          ref.read(paymentListControllerProvider.notifier).refresh(),
      child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Failed to load payments',
            onRetry: () => ref.invalidate(paymentListControllerProvider),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.payments_outlined,
                  message: 'No payment records yet.\nTap + to add one.',
                ),
              ],
            );
          }
          final total = records.fold<double>(0, (s, r) => s + r.amount);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: records.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) return _SummaryCard(total: total);
              return _PaymentRow(record: records[i - 1]);
            },
          );
        },
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppColors.iconWrapDecoration(
              AppColors.teal.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Recorded',
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '৳ ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppText.brandFontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment Row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.record});

  final PaymentRecord record;

  Color _methodColor() {
    switch (record.method) {
      case 'bkash':
        return AppColors.purple;
      case 'bank':
        return AppColors.teal;
      default:
        return AppColors.gold;
    }
  }

  IconData _methodIcon() {
    switch (record.method) {
      case 'bkash':
        return Icons.phone_android_outlined;
      case 'bank':
        return Icons.account_balance_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  Color _typeColor() {
    switch (record.type) {
      case 'advance':
        return AppColors.green;
      case 'extra':
        return AppColors.purple;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodColor = _methodColor();
    final d = record.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: AppColors.iconWrapDecoration(
            methodColor.withValues(alpha: 0.15),
          ),
          child: Icon(_methodIcon(), color: methodColor, size: 20),
        ),
        title: Text(
          '৳ ${record.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppColors.film,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${record.method.toUpperCase()} · $dateStr',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _typeColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _typeColor().withValues(alpha: 0.3)),
          ),
          child: Text(
            record.type[0].toUpperCase() + record.type.substring(1),
            style: TextStyle(
              color: _typeColor(),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
