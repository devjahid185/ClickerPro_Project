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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../core/format/currency.dart';
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
        loading: () => SizedBox(
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
          final outstanding =
              (bookingTotal == null
                      ? agg.due
                      : (bookingTotal! - collected).clamp(0.0, double.infinity))
                  .toDouble();
          final hasOutstanding = outstanding > 0.5;
          return Column(
            children: [
              _row(
                'Advance paid',
                agg.advance,
                lang,
                amountColor: AppColors.green,
              ),
              _divider(),
              _row('Due paid', agg.due, lang, amountColor: AppColors.green),
              if (agg.extra > 0.5) ...[
                _divider(),
                _row(
                  'Extra paid',
                  agg.extra,
                  lang,
                  amountColor: AppColors.green,
                ),
              ],
              _divider(),
              _row('Total paid', collected, lang, amountColor: AppColors.green),
              if (bookingTotal != null) ...[
                _divider(),
                _row(
                  'Remaining due',
                  hasOutstanding ? outstanding : 0,
                  lang,
                  amountColor: hasOutstanding
                      ? AppColors.red
                      : AppColors.filmDim,
                ),
                _divider(),
                _row('Booking total', bookingTotal!, lang, emphasized: true),
              ],
              if (canEditPayments && hasOutstanding) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Partial: record any amount the client actually paid now
                    // (not the full due). "পার্শিয়াল পেমেন্ট অপশন".
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add_card_outlined, size: 18),
                        label: const Text('Partial'),
                        onPressed: () =>
                            _recordPartial(context, ref, outstanding),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Full: clear the whole remaining due in one tap.
                    Expanded(
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
                        label: const Text('Full due'),
                        onPressed: () =>
                            _markDueReceived(context, ref, outstanding),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Records the full outstanding amount as a collected `due` payment,
  /// clearing the booking's due. The dashboard's collection/due figures and
  /// the finance screen pick it up because they read the same aggregate.
  Future<void> _markDueReceived(
    BuildContext context,
    WidgetRef ref,
    double amount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Payment received?',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Text(
          'Marking ৳${amount.toStringAsFixed(0)} as received will add it to '
          'collection and clear the remaining due.',
          style: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Yes, received'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _savePayment(context, ref, amount, note: 'Due collected');
  }

  /// Records a PARTIAL payment — any amount the client paid now, up to the
  /// outstanding [outstanding]. The remaining due stays open for later.
  /// This is the "পার্শিয়াল পেমেন্ট" flow for clients who don't pay in full.
  Future<void> _recordPartial(
    BuildContext context,
    WidgetRef ref,
    double outstanding,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Partial payment',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding: ৳${outstanding.toStringAsFixed(0)}',
                style: TextStyle(color: AppColors.filmDim, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(color: AppColors.film),
                decoration: InputDecoration(
                  prefixText: '${ActiveCurrency.value.symbol} ',
                  prefixStyle: TextStyle(color: AppColors.gold),
                  labelText: 'Amount received now',
                  labelStyle: TextStyle(color: AppColors.filmDim),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.line(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                ),
                validator: (raw) {
                  final v = double.tryParse((raw ?? '').trim());
                  if (v == null || v <= 0) return 'Enter a valid amount';
                  if (v > outstanding + 0.5) {
                    return 'Cannot exceed the ৳${outstanding.toStringAsFixed(0)} due';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.voidBlack,
            ),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(ctx).pop(double.parse(controller.text.trim()));
            },
            child: Text('Record'),
          ),
        ],
      ),
    );

    if (amount == null || !context.mounted) return;
    await _savePayment(context, ref, amount, note: 'Partial payment');
  }

  /// Shared save path for both full and partial due collection: logs a
  /// `due`-kind [amount] against the booking and refreshes the aggregate,
  /// dashboard due figures, and pops the coin celebration.
  Future<void> _savePayment(
    BuildContext context,
    WidgetRef ref,
    double amount, {
    required String note,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final payment = Payment(
      id: 'p-${now.microsecondsSinceEpoch}',
      bookingId: bookingId,
      kind: PaymentKind.due,
      amount: amount,
      method: 'cash',
      note: note,
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
        SnackBar(
          content: Text(
            '${ActiveCurrency.value.wrap(amount.toStringAsFixed(0))} added to collection ✓',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not mark: $e')));
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
                    ? AppColors.film
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
                  amountColor ?? (emphasized ? AppColors.gold : AppColors.film),
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
    color: AppColors.line(0.04),
  );
}
