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
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/fl_earning_providers.dart';
import '../domain/fl_earning.dart';

class FlEarningsScreen extends ConsumerStatefulWidget {
  const FlEarningsScreen({super.key});

  @override
  ConsumerState<FlEarningsScreen> createState() => _FlEarningsScreenState();
}

class _FlEarningsScreenState extends ConsumerState<FlEarningsScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final lang = 'en';
    final async = ref.watch(flEarningOverviewControllerProvider);

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
          'Earnings',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: AppColors.voidLight,
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
          data: (overview) {
            if (overview.totalEarnings == 0 && overview.owners.isEmpty) {
              return EmptyState(
                message:
                    'No earnings data yet\nPayments from owners will appear here',
                icon: Icons.account_balance_wallet_outlined,
              );
            }
            return _buildContent(context, overview, lang);
          },
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPeriodToggle(),
        const SizedBox(height: 16),
        _buildSummaryCards(overview, lang),
        const SizedBox(height: 20),
        _buildSectionHeader('Per-Owner Breakdown'),
        const SizedBox(height: 10),
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
      ],
    );
  }

  // ─── Period Toggle ────────────────────────────────────────────────

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: AppColors.teal.withValues(alpha: 0.30))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.teal : AppColors.filmDim,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Summary Cards (FL-01) ───────────────────────────────────────

  Widget _buildSummaryCards(FlEarningsOverview o, String lang) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL',
            value: BookingFormat.money(
              o.totalEarnings,
              lang: lang,
              bnNumerals: lang == 'bn',
            ),
            color: AppColors.teal,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'RECEIVED',
            value: BookingFormat.money(
              o.receivedAmount,
              lang: lang,
              bnNumerals: lang == 'bn',
            ),
            color: AppColors.green,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'PENDING',
            value: BookingFormat.money(
              o.pendingAmount,
              lang: lang,
              bnNumerals: lang == 'bn',
            ),
            color: AppColors.coral,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

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
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EARNINGS HISTORY',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
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
              fontFamily: 'Poppins',
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
                    color: AppColors.teal,
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
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Send'),
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
        icon: const Icon(Icons.send_outlined, size: 18),
        label: const Text('Request Payment'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.filmMuted,
      ),
    );
  }
}

// ─── Summary Card ──────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
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
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
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
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.teal,
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
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.film,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${owner.eventsCount} events',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
          Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
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
                    fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
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
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
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
            child: const Icon(
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
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.film,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${BookingFormat.money(payment.amount, lang: lang, bnNumerals: lang == 'bn')} · ${payment.pendingDays} days pending',
                  style: TextStyle(
                    fontFamily: 'Poppins',
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
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.green,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Remind',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
            fontSize: 8,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: barHeight.clamp(4.0, 90.0),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
