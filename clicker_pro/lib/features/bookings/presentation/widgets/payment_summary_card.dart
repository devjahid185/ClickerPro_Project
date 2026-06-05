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
import '../../../../features/settings/application/language_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../application/booking_providers.dart';
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
  const PaymentSummaryCard({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');
    final aggregateAsync = ref.watch(paymentAggregateProvider(bookingId));

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
          return Column(
            children: [
              _row('Advance', agg.advance, lang, amountColor: AppColors.green),
              _divider(),
              _row(
                'Due',
                agg.due,
                lang,
                amountColor: agg.due > 0 ? AppColors.red : AppColors.filmDim,
              ),
              _divider(),
              _row('Extra', agg.extra, lang),
              _divider(),
              _row('Total', agg.total, lang, emphasized: true),
            ],
          );
        },
      ),
    );
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
