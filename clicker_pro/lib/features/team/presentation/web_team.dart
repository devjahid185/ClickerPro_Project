// lib/features/team/presentation/web_team.dart
//
// Graphy7 — WEB-ONLY team screen (Sunset Studio, from
// design_handoff_clickerpro_web — Screen 5, MOD-08).
//
// Layout per the handoff:
//   1. 4 stat tiles — Members (dark) · Freelancers (orange) · Managers
//      (purple) · Active (green)
//   2. Chief card — full-width gold gradient with the busiest member
//   3. Members card — filter chips + "+ Invite" pill; rows with tinted
//      avatar + status dot, name + phone, role tag pill, event count and a
//      round call button (green-tint hover)
//
// Data: teamMembersProvider (the same list mobile uses) + staffPayoutsProvider
// for per-member event counts. No new business logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/web_motion.dart';
import '../../../theme/web_theme.dart';
import '../application/team_providers.dart';
import '../domain/staff_payout.dart';
import '../domain/team_member.dart';

/// The wide-web team screen. Pure presentation over the existing providers.
class WebTeam extends ConsumerStatefulWidget {
  const WebTeam({super.key, this.onInvite, this.onTapMember});

  final VoidCallback? onInvite;
  final void Function(TeamMember member)? onTapMember;

  @override
  ConsumerState<WebTeam> createState() => _WebTeamState();
}

class _WebTeamState extends ConsumerState<WebTeam> {
  String _roleFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamMembersProvider);
    final members = async.valueOrNull ?? const <TeamMember>[];
    final payouts = ref.watch(staffPayoutsProvider).valueOrNull;
    final eventsByUser = <String, int>{
      for (final p in payouts?.members ?? const <StaffPayout>[])
        p.userId: p.events,
    };

    final freelancers =
        members.where((m) => m.role.toUpperCase() == 'FREELANCER').length;
    final managers =
        members.where((m) => m.role.toUpperCase() == 'MANAGER').length;
    final active =
        members.where((m) => (eventsByUser[m.userId] ?? 0) > 0).length;

    // Chief = the member with the most assigned events (real signal).
    TeamMember? chief;
    var chiefEvents = 0;
    for (final m in members) {
      final e = eventsByUser[m.userId] ?? 0;
      if (e > chiefEvents) {
        chief = m;
        chiefEvents = e;
      }
    }

    final roles = <String>{
      for (final m in members) m.role.toUpperCase(),
    }.toList()
      ..sort();

    final filtered = _roleFilter == 'ALL'
        ? members
        : members
            .where((m) => m.role.toUpperCase() == _roleFilter)
            .toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          WebEntrance(
            delay: const Duration(milliseconds: 50),
            child: _StatTiles(
              members: members.length,
              freelancers: freelancers,
              managers: managers,
              active: active,
            ),
          ),
          if (chief != null) ...[
            const SizedBox(height: 16),
            WebEntrance(
              delay: const Duration(milliseconds: 110),
              child: _ChiefCard(
                member: chief,
                events: chiefEvents,
                onTap: widget.onTapMember == null
                    ? null
                    : () => widget.onTapMember!(chief!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          WebEntrance(
            delay: const Duration(milliseconds: 170),
            child: _MembersCard(
              loading: async.isLoading && members.isEmpty,
              error: async.hasError && members.isEmpty,
              members: filtered,
              roles: roles,
              roleFilter: _roleFilter,
              eventsByUser: eventsByUser,
              onFilter: (r) => setState(() => _roleFilter = r),
              onInvite: widget.onInvite,
              onTapMember: widget.onTapMember,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── STAT TILES
class _StatTiles extends StatelessWidget {
  const _StatTiles({
    required this.members,
    required this.freelancers,
    required this.managers,
    required this.active,
  });

  final int members;
  final int freelancers;
  final int managers;
  final int active;

  @override
  Widget build(BuildContext context) {
    Widget tile({
      required String label,
      required int value,
      Color? bg,
      Color? valueColor,
      Color? labelColor,
      bool dark = false,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: dark ? WebTheme.chrome : WebTheme.surface,
          borderRadius: BorderRadius.circular(WebTheme.rTile),
          border: dark ? null : Border.all(color: WebTheme.hairline),
          boxShadow:
              dark ? WebTheme.darkCardShadow : WebTheme.cardShadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: WebTheme.label(
                  size: 9,
                  tracking: 0.15,
                  color: labelColor ??
                      (dark ? WebTheme.chromeInkMuted : WebTheme.inkMuted),
                )),
            const SizedBox(height: 4),
            Text('$value',
                style: WebTheme.displayStyle(
                  size: 28,
                  weight: FontWeight.w800,
                  color: valueColor ??
                      (dark ? WebTheme.chromeInk : WebTheme.ink),
                )),
          ],
        ),
      );
    }

    final tiles = [
      tile(label: 'MEMBERS', value: members, dark: true),
      tile(
          label: 'FREELANCERS',
          value: freelancers,
          valueColor: WebTheme.orange,
          labelColor: WebTheme.orangeDeep),
      tile(
          label: 'MANAGERS',
          value: managers,
          valueColor: WebTheme.nightText),
      tile(label: 'ACTIVE', value: active, valueColor: WebTheme.success),
    ];

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 680) {
        return Column(children: [
          Row(children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 14),
            Expanded(child: tiles[1]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 14),
            Expanded(child: tiles[3]),
          ]),
        ]);
      }
      return Row(children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i != 0) const SizedBox(width: 14),
          Expanded(child: tiles[i]),
        ],
      ]);
    });
  }
}

// ───────────────────────────────────────────────────────── CHIEF CARD
/// Full-width gold-gradient card with the studio's busiest member.
class _ChiefCard extends StatelessWidget {
  const _ChiefCard({
    required this.member,
    required this.events,
    this.onTap,
  });

  final TeamMember member;
  final int events;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      onTap: onTap,
      borderRadius: WebTheme.rCard,
      enableShadow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: WebTheme.goldBlend,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          boxShadow: WebTheme.goldGlow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: WebTheme.chrome,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.fullName.isEmpty
                      ? '?'
                      : member.fullName[0].toUpperCase(),
                  style: WebTheme.displayStyle(
                      size: 20,
                      weight: FontWeight.w700,
                      color: WebTheme.amber),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${member.fullName} ★',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.displayStyle(
                          size: 17,
                          weight: FontWeight.w700,
                          color: WebTheme.chrome)),
                  const SizedBox(height: 2),
                  Text(
                    'Chief Photographer · $events events',
                    style: WebTheme.bodyStyle(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xB32B1D12)),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.chrome,
                borderRadius: BorderRadius.circular(WebTheme.rFull),
              ),
              child: Text('CHIEF',
                  style: WebTheme.label(
                      size: 9, color: WebTheme.amber, tracking: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── MEMBERS CARD
class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.loading,
    required this.error,
    required this.members,
    required this.roles,
    required this.roleFilter,
    required this.eventsByUser,
    required this.onFilter,
    this.onInvite,
    this.onTapMember,
  });

  final bool loading;
  final bool error;
  final List<TeamMember> members;
  final List<String> roles;
  final String roleFilter;
  final Map<String, int> eventsByUser;
  final ValueChanged<String> onFilter;
  final VoidCallback? onInvite;
  final void Function(TeamMember member)? onTapMember;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        border: Border.all(color: WebTheme.hairline),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Members', style: WebTheme.displayStyle(size: 16)),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('ALL'),
                    for (final r in roles) _filterChip(r),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onInvite != null)
                WebHoverHighlight(
                  onTap: onInvite,
                  borderRadius: WebTheme.rFull,
                  builder: (context, hovering) => AnimatedContainer(
                    duration: WebTheme.base,
                    curve: WebTheme.ease,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: hovering
                          ? WebTheme.orangeDark
                          : WebTheme.orange,
                      borderRadius: BorderRadius.circular(WebTheme.rFull),
                      boxShadow: WebTheme.buttonGlow,
                    ),
                    child: Text('+ Invite',
                        style: WebTheme.bodyStyle(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: WebTheme.chromeInk)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Column(children: [
              WebShimmer(height: 56, borderRadius: 14),
              SizedBox(height: 8),
              WebShimmer(height: 56, borderRadius: 14),
              SizedBox(height: 8),
              WebShimmer(height: 56, borderRadius: 14),
            ])
          else if (error)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('Could not load the team.',
                  textAlign: TextAlign.center,
                  style: WebTheme.bodyStyle(
                      size: 12.5, color: WebTheme.inkMuted)),
            )
          else if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('No team members yet — invite your first one.',
                  textAlign: TextAlign.center,
                  style: WebTheme.bodyStyle(
                      size: 12.5, color: WebTheme.inkMuted)),
            )
          else
            for (var i = 0; i < members.length; i++) ...[
              if (i != 0) const SizedBox(height: 8),
              WebEntrance(
                delay: Duration(milliseconds: (45 * i).clamp(0, 400)),
                offset: 6,
                child: _MemberRow(
                  member: members[i],
                  events: eventsByUser[members[i].userId] ?? 0,
                  index: i,
                  onTap: onTapMember == null
                      ? null
                      : () => onTapMember!(members[i]),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final active = roleFilter == label;
    return WebHoverHighlight(
      onTap: () => onFilter(label),
      borderRadius: WebTheme.rFull,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? WebTheme.orange
              : hovering
                  ? WebTheme.orangeTint
                  : WebTheme.pageBg,
          borderRadius: BorderRadius.circular(WebTheme.rFull),
          border: Border.all(
              color: active ? WebTheme.orange : WebTheme.innerLine),
        ),
        child: Text(label,
            style: WebTheme.label(
              size: 9,
              tracking: 0.08,
              color: active ? WebTheme.chromeInk : WebTheme.inkMuted,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── MEMBER ROW
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.events,
    required this.index,
    this.onTap,
  });

  final TeamMember member;
  final int events;
  final int index;
  final VoidCallback? onTap;

  static const _avatarTints = [
    (WebTheme.orangeTint, WebTheme.orangeDeep),
    (WebTheme.nightTint, WebTheme.nightText),
    (WebTheme.successTint, WebTheme.success),
    (WebTheme.amberTint, WebTheme.amberText),
  ];

  (Color, Color, Color) _roleColors(String role) {
    switch (role.toUpperCase()) {
      case 'FREELANCER':
        return (
          WebTheme.orangeTint,
          WebTheme.orangeTintBorder,
          WebTheme.orangeDeep
        );
      case 'MANAGER':
        return (
          WebTheme.nightTint,
          WebTheme.nightTintBorder,
          WebTheme.nightText
        );
      default:
        return (
          WebTheme.amberTint,
          WebTheme.amberTintBorder,
          WebTheme.amberText
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _avatarTints[index % _avatarTints.length];
    final role = _roleColors(member.role);
    final phone = member.phone?.trim();
    // Real activity signal: a member with assigned events shows green.
    final statusColor = events > 0 ? WebTheme.success : WebTheme.tan;

    return WebHoverHighlight(
      onTap: onTap,
      borderRadius: WebTheme.rRow,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: hovering ? WebTheme.orangeTint : WebTheme.pageBg,
          borderRadius: BorderRadius.circular(WebTheme.rRow),
          border: Border.all(
              color: hovering ? WebTheme.orange : WebTheme.innerLine),
        ),
        child: Row(
          children: [
            // Avatar + status dot.
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: tint.$1, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        member.fullName.isEmpty
                            ? '?'
                            : member.fullName[0].toUpperCase(),
                        style: WebTheme.bodyStyle(
                            size: 14,
                            weight: FontWeight.w700,
                            color: tint.$2),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WebTheme.bodyStyle(
                          size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    phone?.isNotEmpty == true ? phone! : member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WebTheme.bodyStyle(
                        size: 11, color: WebTheme.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: role.$1,
                borderRadius: BorderRadius.circular(WebTheme.rFull),
                border: Border.all(color: role.$2),
              ),
              child: Text(member.role.toUpperCase(),
                  style: WebTheme.label(
                      size: 9, color: role.$3, tracking: 0.08)),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 52,
              child: Text(
                '$events ev',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: WebTheme.mono,
                  fontSize: 11,
                  color: WebTheme.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _CallButton(phone: phone),
          ],
        ),
      ),
    );
  }
}

/// Round ✆ button — green tint on hover; disabled when no phone on file.
class _CallButton extends StatelessWidget {
  const _CallButton({this.phone});
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final enabled = phone?.isNotEmpty == true;
    return WebHoverHighlight(
      onTap: enabled
          ? () => launchUrl(Uri(scheme: 'tel', path: phone!))
          : null,
      borderRadius: 999,
      builder: (context, hovering) => AnimatedContainer(
        duration: WebTheme.base,
        curve: WebTheme.ease,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled && hovering
              ? WebTheme.successTint
              : WebTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled && hovering
                ? WebTheme.successTintBorder
                : WebTheme.hairline,
          ),
        ),
        child: Center(
          child: Text(
            '✆',
            style: TextStyle(
              fontSize: 15,
              height: 1,
              color: !enabled
                  ? WebTheme.inkFaint
                  : hovering
                      ? WebTheme.success
                      : WebTheme.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
