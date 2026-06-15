// lib/features/payments/presentation/payment_entry_screen.dart
//
// Standalone Payment Entry screen — lists all payment records and allows
// recording new payments via the PaymentEntrySheet bottom-sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/payment_providers.dart';
import '../domain/payment_record.dart';
import 'payment_entry_sheet.dart';

class PaymentEntryScreen extends ConsumerWidget {
  const PaymentEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentListControllerProvider);

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
          'Payment Records',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Record Payment',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          await PaymentEntrySheet.show(context, eventId: '');
          ref.invalidate(paymentListControllerProvider);
        },
      ),
      body: RefreshIndicator(
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
            child: const Icon(
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
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
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
