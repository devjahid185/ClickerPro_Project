// lib/features/team/presentation/web_payouts.dart
//
// Graphy7 — WEB-ONLY freelancer payouts (Graphy7 Design).
//
// A desktop payout sheet, rendered ONLY on wide web. The mobile salary-sheet
// body is 100% untouched (SalarySheetScreen routes here only when
// kIsWeb && width >= 900). Ported from the design source's "Freelancer Payouts"
// screen (#8):
//
//   ┌──────────────────────────────────────────────────────────────┐
//   │  Freelancer Payouts                                Pay All (⊕) │
//   │  N freelancers awaiting payment · ৳X total                    │
//   ├──────────────────────────────────────────────────────────────┤
//   │  ● Zahid Hasan   Lead · 8 events           ৳34,000   [ Pay ]  │
//   │  …                                                            │
//   └──────────────────────────────────────────────────────────────┘
//
// Real owner-side data via `staffPayoutsProvider` (GET /api/team/payouts);
// settling routes through `teamControllerProvider.markPayoutPaid` (offline-
// first). No new business logic — only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/currency.dart';
import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/team_providers.dart';
import '../domain/staff_payout.dart';

/// The wide-web payout sheet. Pure presentation over the existing providers.
class WebPayouts extends ConsumerWidget {
  const WebPayouts({super.key, this.onPay, this.onPayAll});

  /// Settle a single member's outstanding payout.
  final void Function(StaffPayout member)? onPay;

  /// Settle every member with an outstanding balance.
  final VoidCallback? onPayAll;

  static const double _maxContentWidth = 1080;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffPayoutsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WebTheme.sp6,
            WebTheme.sp5,
            WebTheme.sp6,
            WebTheme.sp7,
          ),
          children: [
            WebEntrance(
              child: _Header(
                sheet: async.value,
                onPayAll: onPayAll,
              ),
            ),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: async.when(
                loading: () => const _Card(child: _ListSkeleton()),
                error: (_, _) => const _Card(
                  child: _Message(text: 'Could not load payouts.'),
                ),
                data: (sheet) {
                  final unpaid = sheet.members
                      .where((m) => !m.isFullyPaid)
                      .toList()
                    ..sort((a, b) => b.due.compareTo(a.due));
                  final paid = sheet.members
                      .where((m) => m.isFullyPaid)
                      .toList();
                  final ordered = [...unpaid, ...paid];
                  if (ordered.isEmpty) {
                    return const _Card(
                      child: _Message(text: 'No payouts to show yet.'),
                    );
                  }
                  return _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < ordered.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1, color: WebTheme.hairline),
                          _PayoutRow(
                            member: ordered[i],
                            onPay: onPay == null || ordered[i].isFullyPaid
                                ? null
                                : () => onPay!(ordered[i]),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HEADER
class _Header extends StatelessWidget {
  const _Header({required this.sheet, required this.onPayAll});
  final StaffPayoutSheet? sheet;
  final VoidCallback? onPayAll;

  @override
  Widget build(BuildContext context) {
    final s = sheet;
    final awaiting = s == null
        ? 0
        : s.members.where((m) => !m.isFullyPaid).length;
    final due = s?.totalDue ?? 0;
    final subtitle = s == null
        ? '—'
        : awaiting == 0
            ? 'All staff settled · nothing outstanding'
            : '$awaiting ${awaiting == 1 ? 'freelancer' : 'freelancers'} '
                'awaiting payment · ${_formatBdt((due * 100).round())} total';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Freelancer Payouts',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: WebTheme.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (onPayAll != null && awaiting > 0) ...[
          const SizedBox(width: WebTheme.sp4),
          WebHoverLift(
            onTap: onPayAll,
            borderRadius: WebTheme.rButton,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
              decoration: BoxDecoration(
                color: WebTheme.orange,
                borderRadius: BorderRadius.circular(WebTheme.rButton),
                boxShadow: [
                  BoxShadow(
                    color: WebTheme.orange.withValues(alpha: 0.42),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Pay All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────── CARD
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.member, required this.onPay});
  final StaffPayout member;
  final VoidCallback? onPay;

  /// Deterministic accent so avatars vary but stay stable per member.
  static const _accents = [
    WebTheme.orange,
    WebTheme.teal,
    WebTheme.info,
    WebTheme.success,
    WebTheme.amberDeep,
    WebTheme.rose,
  ];

  Color get _accent => _accents[member.userId.hashCode.abs() % _accents.length];

  String get _initials {
    final parts = member.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final paid = member.isFullyPaid;
    final eventsLabel =
        '${member.events} ${member.events == 1 ? 'event' : 'events'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.trim().isEmpty ? 'Team member' : member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: WebTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  paid
                      ? '$eventsLabel · fully paid'
                      : '$eventsLabel · earned ${_formatBdt((member.earned * 100).round())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBdt(((paid ? member.earned : member.due) * 100).round()),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: paid ? WebTheme.inkMuted : WebTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                paid ? 'PAID' : 'DUE',
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: paid ? WebTheme.success : WebTheme.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          _PayButton(paid: paid, onTap: onPay),
        ],
      ),
    );
  }
}

/// The dark per-row action ("Pay") from the design source. Becomes a settled
/// green "Paid ✓" chip once the member has nothing outstanding.
class _PayButton extends StatelessWidget {
  const _PayButton({required this.paid, required this.onTap});
  final bool paid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (paid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: WebTheme.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(WebTheme.rChip),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 15, color: WebTheme.success),
            SizedBox(width: 4),
            Text(
              'Paid',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: WebTheme.success,
              ),
            ),
          ],
        ),
      );
    }
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rChip,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: WebTheme.chrome,
          borderRadius: BorderRadius.circular(WebTheme.rChip),
        ),
        child: const Text(
          'Pay',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: List.generate(
          5,
          (i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                WebShimmer(width: 44, height: 44, borderRadius: 22),
                SizedBox(width: 14),
                Expanded(child: WebShimmer(height: 14, borderRadius: 6)),
                SizedBox(width: 40),
                WebShimmer(width: 70, height: 14, borderRadius: 6),
                SizedBox(width: 16),
                WebShimmer(width: 64, height: 34, borderRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebTheme.sageTint,
                borderRadius: BorderRadius.circular(WebTheme.rChip),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: WebTheme.inkMuted, size: 24),
            ),
            const SizedBox(height: WebTheme.sp3),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WebTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── HELPERS
String _formatBdt(int minor) {
  final taka = (minor / 100).round();
  final s = taka.toString();
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return ActiveCurrency.value.wrap(buf.toString().split('').reversed.join());
}
