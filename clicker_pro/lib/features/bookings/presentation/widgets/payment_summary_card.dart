// lib/features/bookings/presentation/widgets/payment_summary_card.dart
//
// Renders the four-line payment summary for the booking detail screen:
// advance / due / extra / total. Reads the aggregate from the payment
// repository via a dedicated `FutureProvider.family` so the card can
// recompute cheaply when payments change.
//
// Visibility is gated by the screen — the card simply renders. The
// screen's `shouldShowPayment` predicate decides whether to mount this
// widget at all (Property 3).
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Components and Interfaces". Validates Requirements 5.2, 12.4.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../core/role/capability.dart';
import '../../../../features/settings/application/language_controller.dart';
import '../../../../shared/widgets/celebration.dart';
import '../../../../theme/app_colors.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../application/booking_providers.dart';
import '../../domain/payment.dart';
import '../../domain/payment_kind.dart';
import 'detail_section.dart';

/// One-shot future for the payment aggregate of a booking. Family-keyed
/// so each booking's summary caches independently.
final paymentAggregateProvider =
    FutureProvider.family<
      ({double advance, double due, double extra, double total}),
      String
    >((ref, bookingId) {
      return ref.read(paymentRepositoryProvider).aggregateForBooking(bookingId);
    });

class PaymentSummaryCard extends ConsumerWidget {
  const PaymentSummaryCard({
    super.key,
    required this.bookingId,
    this.bookingTotal,
  });

  final String bookingId;

  /// The booking's agreed price (customPrice or package base price). Used
  /// to compute the OUTSTANDING due so a single tap clears it into the
  /// collected column.
  final double? bookingTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');
    final aggregateAsync = ref.watch(paymentAggregateProvider(bookingId));
    final canEditPayments = ref
        .watch(bookingsPolicyProvider)
        .can(Capability.editBookingPayments);

    return DetailSection(
      title: 'Payments',
      child: aggregateAsync.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
        error: (err, _) => Text(
          'Could not load payments.',
          style: TextStyle(color: AppColors.red.withValues(alpha: 0.85)),
        ),
        data: (agg) {
          // Outstanding = agreed price − everything collected so far.
          final collected = agg.total;
          final outstanding = bookingTotal == null
              ? agg.due
              : (bookingTotal! - collected);
          final hasOutstanding = outstanding > 0.5;
          return Column(
            children: [
              _row('Advance', agg.advance, lang, amountColor: AppColors.green),
              _divider(),
              _row(
                'Collected',
                collected,
                lang,
                amountColor: AppColors.green,
              ),
              _divider(),
              _row(
                'Due',
                hasOutstanding ? outstanding : 0,
                lang,
                amountColor: hasOutstanding ? AppColors.red : AppColors.filmDim,
              ),
              if (bookingTotal != null) ...[
                _divider(),
                _row('Total', bookingTotal!, lang, emphasized: true),
              ],
              if (canEditPayments && hasOutstanding) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'বকেয়া ৳${outstanding.toStringAsFixed(0)} পেয়েছি — মার্ক করুন',
                    ),
                    onPressed: () =>
                        _markDueReceived(context, ref, outstanding),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Records the outstanding amount as a collected `due` payment, clearing
  /// the booking's due. The dashboard's collection/due figures and the
  /// finance screen pick it up because they read the same payment
  /// aggregate.
  Future<void> _markDueReceived(
    BuildContext context,
    WidgetRef ref,
    double amount,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: const Text(
          'পেমেন্ট পেয়েছি?',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Text(
          'বকেয়া ৳${amount.toStringAsFixed(0)} আদায় হয়েছে বলে মার্ক করলে এটা '
          'কালেকশন-এ যোগ হবে এবং আর কোনো বকেয়া থাকবে না।',
          style: const TextStyle(color: AppColors.filmDim, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('বাতিল',
                style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('হ্যাঁ, পেয়েছি'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final now = DateTime.now();
    final payment = Payment(
      id: 'p-${now.microsecondsSinceEpoch}',
      bookingId: bookingId,
      kind: PaymentKind.due,
      amount: amount,
      method: 'cash',
      note: 'Due collected',
      paidAt: now,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    try {
      await ref
          .read(paymentRepositoryProvider)
          .add(payment, policy: ref.read(bookingsPolicyProvider));
      ref.invalidate(paymentAggregateProvider(bookingId));
      ref.invalidate(dueBreakdownProvider);
      // 🪙 payment received — coin-pop celebration.
      if (context.mounted) Celebration.coinPop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('বকেয়া কালেকশন-এ যোগ হয়েছে ✓')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('মার্ক করা যায়নি: $e')),
      );
    }
  }

  Widget _row(
    String label,
    double amount,
    String lang, {
    bool emphasized = false,
    Color? amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? Colors.white
                    : AppColors.filmMuted.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            BookingFormat.money(amount, lang: lang, bnNumerals: lang == 'bn'),
            style: TextStyle(
              color:
                  amountColor ?? (emphasized ? AppColors.gold : Colors.white),
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 2),
    color: Colors.black.withValues(alpha: 0.04),
  );
}
