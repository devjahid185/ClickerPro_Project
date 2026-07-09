// lib/features/team/presentation/web_team.dart
//
// Graphy7 — WEB-ONLY team members (Graphy7 Design).
//
// A desktop members grid, rendered ONLY on wide web. The mobile team body is
// 100% untouched (TeamScreen routes here only when kIsWeb && width >= 900).
// Ported from the design source's "Team Members" screen: a header with an
// Invite CTA and a responsive 3-up grid of member cards (avatar, name, role,
// status pill, contact rows).
//
// Data comes from the same `teamMembersProvider` the mobile screen uses — no
// new business logic, only a web presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/team_providers.dart';
import '../domain/team_member.dart';

/// The wide-web team grid. Pure presentation over the existing providers.
class WebTeam extends ConsumerWidget {
  const WebTeam({super.key, this.onInvite, this.onTapMember});

  final VoidCallback? onInvite;
  final void Function(TeamMember member)? onTapMember;

  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamMembersProvider);

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
              child: _Header(count: async.value?.length, onInvite: onInvite),
            ),
            const SizedBox(height: WebTheme.sp5),
            WebEntrance(
              delay: const Duration(milliseconds: 55),
              child: async.when(
                loading: () => const _Grid(
                  children: [_CardSkeleton(), _CardSkeleton(), _CardSkeleton()],
                ),
                error: (_, _) => const _Message(text: 'Could not load team.'),
                data: (members) {
                  if (members.isEmpty) {
                    return const _Message(
                      text: 'No team members yet — invite your first one.',
                    );
                  }
                  return _Grid(
                    children: [
                      for (final m in members)
                        _MemberCard(
                          member: m,
                          onTap: onTapMember == null
                              ? null
                              : () => onTapMember!(m),
                        ),
                    ],
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
  const _Header({this.count, this.onInvite});
  final int? count;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final n = count == null ? '—' : '$count';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Team Members',
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
                count == 1 ? '1 member' : '$n members',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (onInvite != null) ...[
          const SizedBox(width: WebTheme.sp4),
          WebHoverLift(
            onTap: onInvite,
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
                  Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Invite Member',
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

/// Responsive 3-up / 2-up / 1-up grid of equal-width cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        const gap = WebTheme.sp4;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: cardW, child: child),
          ],
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final TeamMember member;
  final VoidCallback? onTap;

  /// Deterministic accent so avatars vary but stay stable per member.
  static const _accents = [
    WebTheme.orange,
    WebTheme.teal,
    WebTheme.info,
    WebTheme.success,
    WebTheme.amberDeep,
    WebTheme.rose,
  ];

  Color get _accent =>
      _accents[member.userId.hashCode.abs() % _accents.length];

  String get _initials {
    final parts =
        member.fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String get _roleLabel {
    final r = member.role.replaceAll('_', ' ').toLowerCase();
    return r.isEmpty
        ? 'Member'
        : r
            .split(' ')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rPanel,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rPanel),
          border: Border.all(color: WebTheme.hairline),
          boxShadow: WebTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: WebTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roleLabel,
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: WebTheme.hairline),
            const SizedBox(height: 14),
            _ContactRow(icon: Icons.mail_outline_rounded, text: member.email),
            if ((member.phone ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _ContactRow(
                icon: Icons.phone_outlined,
                text: member.phone!.trim(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: WebTheme.inkFaint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: WebTheme.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────── LOADING / EMPTY
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              WebShimmer(width: 50, height: 50, borderRadius: 14),
              SizedBox(width: 13),
              Expanded(child: WebShimmer(height: 16, borderRadius: 6)),
            ],
          ),
          SizedBox(height: 20),
          WebShimmer(height: 12, borderRadius: 4),
          SizedBox(height: 10),
          WebShimmer(height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rPanel),
        border: Border.all(color: WebTheme.hairline),
      ),
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
              child: const Icon(Icons.groups_outlined,
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
