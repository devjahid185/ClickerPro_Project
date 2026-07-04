// lib/features/freelancer/presentation/fl_earnings_screen.dart
//
// Freelancer Earnings Dashboard — FL-01 to FL-04.
//
// Layout:
//   ┌─────────────────────────────────┐
//   │ AppBar: ← Earnings             │
//   ├─────────────────────────────────┤
//   │ Toggle: Monthly | Yearly        │
//   ├─────────────────────────────────┤
//   │ 3 summary cards                 │
//   │   Total (teal) | Received (grn) │
//   │   Pending (coral)               │
//   ├─────────────────────────────────┤
//   │ Per-Owner Cards (FL-02)         │
//   │   Studio · events · earned · due│
//   ├─────────────────────────────────┤
//   │ Pending Payments (FL-03)        │
//   │   Owner · amount · Remind btn   │
//   ├─────────────────────────────────┤
//   │ Monthly Bar Chart (FL-04)       │
//   │ 6-month bars + Yearly Recap     │
//   ├─────────────────────────────────┤
//   │ [Request Payment] button        │
//   └─────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/fl_earning_providers.dart';
import '../domain/fl_earning.dart';
import '../../../theme/app_theme.dart';

/// Freelancer finance body — embedded inside FinanceScreen (pure
/// Freelancer role, and the Freelancer tab of the Both role). This used
/// to be a standalone "My Earnings" screen; per Heaven's feedback the
/// freelancer's money view lives in Finance now, so this widget carries
/// no Scaffold/AppBar of its own.
class FlEarningsBody extends ConsumerStatefulWidget {
  const FlEarningsBody({super.key});

  @override
  ConsumerState<FlEarningsBody> createState() => _FlEarningsBodyState();
}

class _FlEarningsBodyState extends ConsumerState<FlEarningsBody> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final lang = 'en';
    final async = ref.watch(flEarningOverviewControllerProvider);

    return RefreshIndicator(
      color: AppColors.orange,
      backgroundColor: AppColors.surface,
      onRefresh: () =>
          ref.read(flEarningOverviewControllerProvider.notifier).refresh(),
      child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Failed to load earnings',
            onRetry: () => ref
                .read(flEarningOverviewControllerProvider.notifier)
                .refresh(),
          ),
        ),
        // Always render the full dashboard — when there are no earnings yet
        // the summary cards simply read ৳0 (a clean premium "00" template)
        // instead of a bare empty page.
        data: (overview) => _buildContent(context, overview, lang),
      ),
    );
  }

  // ─── Content ───────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    FlEarningsOverview overview,
    String lang,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPeriodToggle(),
        const SizedBox(height: 16),
        _buildEarningsHero(overview, lang),
        const SizedBox(height: 20),
        _buildSectionHeader('Per-Owner Breakdown'),
        const SizedBox(height: 10),
        if (overview.owners.isEmpty)
          _buildEmptyHint(
            'No payouts yet',
            'Earnings from the studios you work with will show up here.',
          )
        else
          ...overview.owners.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OwnerCard(owner: o, lang: lang),
            ),
          ),
        if (overview.pendingPayments.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildSectionHeader('Pending Payments'),
          const SizedBox(height: 10),
          ...overview.pendingPayments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingPaymentRow(payment: p, lang: lang),
            ),
          ),
        ],
        // Which specific events still owe this freelancer money.
        if (overview.pendingEvents.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildSectionHeader('Events Awaiting Payment'),
          const SizedBox(height: 10),
          ...overview.pendingEvents.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PendingEventRow(event: e, lang: lang),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildSectionHeader('Monthly Chart'),
        const SizedBox(height: 10),
        _buildMonthlyChart(overview.yearlyRecap, lang),
        const SizedBox(height: 10),
        if (overview.yearlyRecap.bestMonth != null ||
            overview.yearlyRecap.bestOwner != null)
          _buildYearlyRecap(overview.yearlyRecap, lang),
        const SizedBox(height: 24),
        _buildRequestPaymentButton(context),
        const SizedBox(height: 10),
        // Which teams this freelancer belongs to — payments above are
        // broken down per-owner, this is the roster view.
        OutlinedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.freelancerCompanies),
          icon: const Icon(Icons.business_outlined, size: 18),
          label: const Text('My Teams'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orange,
            side: BorderSide(color: AppColors.orange.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Period Toggle ────────────────────────────────────────────────

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          _toggleButton('Monthly', !_isYearly, () {
            setState(() => _isYearly = false);
          }),
          _toggleButton('Yearly', _isYearly, () {
            setState(() => _isYearly = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.filmDim,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Earnings Hero (MOD-16) ──────────────────────────────────────
  //
  // Solid orange "AVAILABLE TO REQUEST" card — the pending amount is what a
  // freelancer can request. Received/Total stay visible as inline stats so
  // no data from the old three-card layout is lost.

  Widget _buildEarningsHero(FlEarningsOverview o, String lang) {
    String money(double v) =>
        BookingFormat.money(v, lang: lang, bnNumerals: lang == 'bn');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE TO REQUEST',
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: AppColors.onAccent.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  money(o.pendingAmount),
                  style: TextStyle(
                    color: AppColors.onAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.03 * 32,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'From ${o.owners.length} '
                  '${o.owners.length == 1 ? "studio" : "studios"}',
                  style: TextStyle(
                    color: AppColors.onAccent.withValues(alpha: 0.82),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _heroStat('RECEIVED', money(o.receivedAmount)),
                    const SizedBox(width: 24),
                    _heroStat('TOTAL', money(o.totalEarnings)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Soft radial bleed instead of a hard-edged ring.
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.onAccent.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          color: AppColors.onAccent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  // ─── Monthly Bar Chart (FL-04) ──────────────────────────────────

  Widget _buildMonthlyChart(FlYearlyRecap recap, String lang) {
    final monthly = recap.monthly;
    if (monthly.isEmpty) return const SizedBox.shrink();

    final maxVal = monthly
        .map((m) => m.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EARNINGS HISTORY',
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < monthly.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _BarColumn(
                      label: monthly[i].month,
                      amount: monthly[i].amount,
                      ratio: maxVal > 0 ? monthly[i].amount / maxVal : 0,
                      lang: lang,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Yearly Recap ────────────────────────────────────────────────

  Widget _buildYearlyRecap(FlYearlyRecap recap, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YEARLY RECAP',
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (recap.bestMonth != null)
                Expanded(
                  child: _RecapStat(
                    label: 'Best Month',
                    value: recap.bestMonth!.month,
                    sub: BookingFormat.money(
                      recap.bestMonth!.amount,
                      lang: lang,
                      bnNumerals: lang == 'bn',
                    ),
                    color: AppColors.orange,
                  ),
                ),
              if (recap.bestMonth != null && recap.bestOwner != null)
                const SizedBox(width: 12),
              if (recap.bestOwner != null)
                Expanded(
                  child: _RecapStat(
                    label: 'Best Owner',
                    value: recap.bestOwner!.ownerName,
                    sub: '${recap.bestOwner!.eventsCount} events',
                    color: AppColors.gold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Request Payment Button ──────────────────────────────────────

  Widget _buildRequestPaymentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.voidLight,
              title: Text(
                'Request Payment',
                style: TextStyle(color: AppColors.film),
              ),
              content: Text(
                'A due-payment request will be sent to the Owner in-app — '
                'including your profile bKash & bank details.',
                style: TextStyle(color: AppColors.filmDim),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.filmDim),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.onAccent,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Send'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;

          try {
            // Attach the freelancer's payout details from their profile
            // so the owner can pay without asking for numbers.
            final me = ref.read(currentUserProvider).valueOrNull;
            final overview = ref
                .read(flEarningOverviewControllerProvider)
                .valueOrNull;
            final sent = await ref
                .read(flEarningRepositoryProvider)
                .requestPayment(
                  amount: overview?.pendingAmount,
                  bkash: me?.bkash,
                  bankDetails: me?.bankDetails,
                );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  sent
                      ? 'Due-payment request sent to the Owner ✓'
                      : 'Failed to send the request',
                ),
                backgroundColor: sent ? AppColors.green : AppColors.red,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            final msg = e.toString().contains('not in any owner')
                ? 'You are not in any Owner team yet — join a team first.'
                : 'Network error — try again';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.red),
            );
          }
        },
        icon: const Icon(Icons.send_rounded, size: 18),
        label: Text(
          'Request Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.onAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 26, height: 1.5, color: AppColors.orange),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: AppText.monoFontFamily,
            fontSize: 10,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }

  /// Soft inline placeholder shown inside the dashboard when a section has no
  /// data yet — keeps the premium "00" layout instead of a blank gap.
  Widget _buildEmptyHint(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.orange.withValues(alpha: 0.7),
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.film,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.filmDim.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Owner Card (FL-02) ──────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.lang});

  final FlOwnerEarning owner;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_outlined,
                  color: AppColors.primary700,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.ownerName,
                      style: TextStyle(
                        fontFamily: AppText.brandFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.film,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${owner.eventsCount} events',
                      style: TextStyle(
                        fontFamily: AppText.brandFontFamily,
                        fontSize: 11,
                        color: AppColors.filmDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.line(0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ownerMetric(
                'Earned',
                BookingFormat.money(
                  owner.earnedAmount,
                  lang: lang,
                  bnNumerals: lang == 'bn',
                ),
                AppColors.green,
              ),
              const SizedBox(width: 16),
              _ownerMetric(
                'Pending',
                BookingFormat.money(
                  owner.pendingAmount,
                  lang: lang,
                  bnNumerals: lang == 'bn',
                ),
                AppColors.coral,
              ),
              const Spacer(),
              if (owner.lastPaymentDate != null)
                Text(
                  'Last: ${_formatDate(owner.lastPaymentDate!)}',
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 10,
                    color: AppColors.filmDim.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerMetric(String label, String value, Color color) {
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ─── Pending Payment Row (FL-03) ─────────────────────────────────

class _PendingPaymentRow extends StatelessWidget {
  const _PendingPaymentRow({required this.payment, required this.lang});

  final FlPendingPayment payment;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final url = _whatsappUrl(payment.ownerPhone);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.hourglass_bottom_outlined,
              color: AppColors.coral,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.ownerName,
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.film,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${BookingFormat.money(payment.amount, lang: lang, bnNumerals: lang == 'bn')} · ${payment.pendingDays} days pending',
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 11,
                    color: AppColors.filmDim.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (url != null && await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.green,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Remind',
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uri? _whatsappUrl(String phone) {
    if (phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return Uri.parse('https://wa.me/$digits');
  }
}

// ─── Bar Column (FL-04) ──────────────────────────────────────────

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.lang,
  });

  final String label;
  final double amount;
  final double ratio;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final barHeight = 90.0 * ratio;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          BookingFormat.money(amount, lang: lang, bnNumerals: lang == 'bn'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 8,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: barHeight.clamp(4.0, 90.0),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ─── Recap Stat ──────────────────────────────────────────────────

class _RecapStat extends StatelessWidget {
  const _RecapStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            fontFamily: AppText.brandFontFamily,
            fontSize: 11,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// One unpaid event row — which shoot still owes the freelancer, for which
/// studio, in what role, and how much.
class _PendingEventRow extends StatelessWidget {
  const _PendingEventRow({required this.event, required this.lang});

  final FlPendingEvent event;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date == null
        ? ''
        : BookingFormat.dateTime(event.date!, lang: lang);
    final meta = <String>[
      if (event.ownerName.isNotEmpty) event.ownerName,
      if (event.role.isNotEmpty)
        event.role[0].toUpperCase() + event.role.substring(1),
      if (dateStr.isNotEmpty) dateStr,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.event_note_outlined,
              color: AppColors.gold,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.film,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 11,
                      color: AppColors.filmDim.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            BookingFormat.money(
              event.amount,
              lang: lang,
              bnNumerals: lang == 'bn',
            ),
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
