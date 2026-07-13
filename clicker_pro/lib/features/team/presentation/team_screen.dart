import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/team_providers.dart';
import '../data/team_api.dart' show TeamMemberProfile;
import '../domain/team_member.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/web_shell.dart';
import 'web_team.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final membersAsync = ref.watch(teamMembersProvider);

    // On wide web the WebNavShell owns the chrome; render the dedicated desktop
    // members grid instead of the mobile body. Mobile + narrow web unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: WebTeam(
          onInvite: () => _showInviteSheet(context, ref),
          onTapMember: (m) => showModalBottomSheet<void>(
            context: context,
            backgroundColor: AppColors.voidLight,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _MemberProfileSheet(member: m),
          ),
        ),
      );
    }

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
          loc.menu_team,
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 20,
          ),
        ),
        actions: [
          // Solid orange "Invite" pill from the .dc.html header.
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => _showInviteSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 17,
                      color: AppColors.onAccent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Invite',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _PendingInvitesBanner(),
          Expanded(
            child: membersAsync.when(
              loading: () => const LensLoader(),
              error: (err, _) => ErrorState(
                message: loc.team_load_failed,
                onRetry: () => ref.invalidate(teamMembersProvider),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    message: loc.team_empty,
                    actionLabel: loc.team_invite_member,
                    onAction: () => _showInviteSheet(context, ref),
                  );
                }
                final groups = _groupByRole(members);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                  children: [
                    // Cap + centre on wide web so the two-up member grid stays
                    // a comfortable width; mobile is a plain full-width column.
                    WebFormWidth(
                      maxWidth: 920,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InviteMethodsRow(
                            onPasscode: () => _showInviteSheet(context, ref),
                            onJoin: () => _showJoinSheet(context),
                          ),
                          const SizedBox(height: 18),
                          for (final group in groups) ...[
                            _roleHeader(group.label, group.members.length),
                            const SizedBox(height: 10),
                            // Two-up tile grid on wide web, single column on
                            // mobile / narrow web.
                            WebTwoColumn(
                              runSpacing: 9,
                              children: [
                                for (final m in group.members)
                                  _TeamMemberTile(member: m),
                              ],
                            ),
                            if (group != groups.last)
                              const SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _JoinTeamSheet(),
    );
  }

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InviteSheet(loc: loc, ref: ref),
    );
  }
}

/// Role-group header — mono ink label like "MANAGERS · 1" (.dc.html).
Widget _roleHeader(String label, int count) {
  return Text(
    '$label · $count',
    style: TextStyle(
      fontFamily: AppText.monoFontFamily,
      fontSize: 10,
      letterSpacing: 1.0,
      fontWeight: FontWeight.w600,
      color: AppColors.film,
    ),
  );
}

/// A named bucket of members sharing one role, in display order.
class _RoleGroup {
  const _RoleGroup(this.label, this.members);
  final String label;
  final List<TeamMember> members;
}

/// Buckets members by role in the design's order (owners → managers →
/// freelancers → both → anything else).
List<_RoleGroup> _groupByRole(List<TeamMember> members) {
  const order = ['OWNER', 'MANAGER', 'FREELANCER', 'BOTH'];
  String labelFor(String role) => switch (role) {
    'OWNER' => 'OWNERS',
    'MANAGER' => 'MANAGERS',
    'FREELANCER' => 'FREELANCERS',
    'BOTH' => 'BOTH',
    '' => 'MEMBERS',
    _ => '${role}S',
  };

  final buckets = <String, List<TeamMember>>{};
  for (final m in members) {
    buckets.putIfAbsent(m.role, () => <TeamMember>[]).add(m);
  }
  final keys = buckets.keys.toList()
    ..sort((a, b) {
      final ia = order.indexOf(a);
      final ib = order.indexOf(b);
      return (ia < 0 ? order.length : ia).compareTo(
        ib < 0 ? order.length : ib,
      );
    });
  return [for (final k in keys) _RoleGroup(labelFor(k), buckets[k]!)];
}

/// Avatar/chip tint per role — orange for owner/manager, violet for
/// freelancers, green for everyone else (.dc.html palette).
(Color, Color) _roleTint(String role) => switch (role) {
  'OWNER' || 'MANAGER' => (AppColors.orangeSoft, AppColors.primary700),
  'FREELANCER' => (AppColors.purpleSoft, AppColors.purple),
  _ => (AppColors.greenSoft, AppColors.green),
};

/// Invite-method tiles row (.dc.html): white cards, orange icon, 11px label.
class _InviteMethodsRow extends StatelessWidget {
  const _InviteMethodsRow({required this.onPasscode, required this.onJoin});

  final VoidCallback onPasscode;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.line(0.06)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.orange),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        tile(Icons.pin_outlined, 'Passcode', onPasscode),
        const SizedBox(width: 9),
        tile(Icons.key_outlined, 'Join Team', onJoin),
      ],
    );
  }
}

/// Banner listing email invites waiting for the logged-in user, with
/// inline Accept / Decline. Hidden when there are none.
class _PendingInvitesBanner extends ConsumerWidget {
  const _PendingInvitesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingTeamInvitesProvider);
    final invites = invitesAsync.valueOrNull ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final invite in invites)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${invite.ownerName} invited you to join the team',
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _inviteAction(
                  context,
                  ref,
                  invite.id,
                  accept: true,
                  icon: Icons.check_rounded,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 4),
                _inviteAction(
                  context,
                  ref,
                  invite.id,
                  accept: false,
                  icon: Icons.close_rounded,
                  color: AppColors.red,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _inviteAction(
    BuildContext context,
    WidgetRef ref,
    String inviteId, {
    required bool accept,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        try {
          await ref
              .read(teamControllerProvider.notifier)
              .respondInvite(inviteId, accept: accept);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                accept ? 'Joined the team ✓' : 'Invite declined',
              ),
            ),
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not complete — please try again.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

/// Bottom sheet where an existing user types the 6-digit numeric
/// passcode to join an owner's team.
class _JoinTeamSheet extends ConsumerStatefulWidget {
  const _JoinTeamSheet();

  @override
  ConsumerState<_JoinTeamSheet> createState() => _JoinTeamSheetState();
}

class _JoinTeamSheetState extends ConsumerState<_JoinTeamSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter the 6-digit code.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(teamControllerProvider.notifier).joinWithCode(code);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined the team ✓')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code is wrong or expired.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.filmDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Join a team',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code from the Owner.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              fontFamily: AppText.monoFontFamily,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '······',
              hintStyle: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.4),
                letterSpacing: 10,
              ),
              filled: true,
              fillColor: AppColors.appBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _join,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Join Team'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberTile extends ConsumerWidget {
  const _TeamMemberTile({required this.member});
  final TeamMember member;

  /// Two-letter initials — first letter of the first two words.
  String get _initials {
    final parts = member.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Short role chip text per the mock ("FL" for freelancers).
  String get _chipLabel =>
      member.role == 'FREELANCER' ? 'FL' : member.role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final (tintBg, tintFg) = _roleTint(member.role);
    final hasAvatar = (member.avatarUrl ?? '').isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showMemberProfile(context, ref),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tintBg,
              image: hasAvatar
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(member.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasAvatar
                ? null
                : Text(
                    _initials,
                    style: TextStyle(
                      color: tintFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            // Only name + phone are shown — email and other personal
            // identifiers are intentionally hidden in the team list.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                if ((member.phone ?? '').isNotEmpty)
                  Text(
                    member.phone!,
                    style: TextStyle(
                      color: AppColors.filmMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tintBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              _chipLabel,
              style: TextStyle(
                fontFamily: AppText.monoFontFamily,
                color: tintFg,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            color: AppColors.voidLight,
            onSelected: (value) async {
              if (value == 'remove') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.voidLight,
                    title: Text(
                      loc.team_remove_confirm_title,
                      style: TextStyle(color: AppColors.film),
                    ),
                    content: Text(
                      '${loc.team_remove_confirm_body} ${member.fullName}?',
                      style: TextStyle(color: AppColors.filmDim),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          loc.gear_cancel,
                          style: TextStyle(color: AppColors.filmDim),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(loc.team_remove),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await ref
                        .read(teamControllerProvider.notifier)
                        .removeMember(member.userId);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.team_remove_failed)),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  loc.team_remove,
                  style: TextStyle(color: AppColors.red),
                ),
              ),
            ],
            icon: Icon(
              Icons.more_vert,
              color: AppColors.filmDim.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Limited member profile sheet — shows ONLY name, photo, phone,
  /// WhatsApp, gear and finance per the privacy rule.
  void _showMemberProfile(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberProfileSheet(member: member),
    );
  }
}

/// Bottom sheet rendering the owner-visible slice of a member profile.
class _MemberProfileSheet extends ConsumerWidget {
  const _MemberProfileSheet({required this.member});
  final TeamMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_memberProfileProvider(member.userId));

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.filmDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.orangeSoft,
                  backgroundImage:
                      (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(member.avatarUrl!)
                      : null,
                  child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                      ? Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary700,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  member.fullName,
                  style: TextStyle(
                    color: AppColors.film,
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if ((member.phone ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    member.phone!,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _contactButton(
                      icon: Icons.call_outlined,
                      label: 'Call',
                      color: AppColors.orange,
                      onTap: () => launchUrl(
                        Uri.parse('tel:${member.phone}'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _contactButton(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      color: AppColors.green,
                      onTap: () {
                        final digits = member.phone!.replaceAll(
                          RegExp(r'[^\d]'),
                          '',
                        );
                        final intl = digits.startsWith('880')
                            ? digits
                            : '880${digits.replaceFirst(RegExp(r'^0'), '')}';
                        // Open a direct WhatsApp chat with a friendly
                        // pre-filled greeting.
                        final hi = Uri.encodeComponent(
                          'Hi ${member.fullName.split(' ').first}, ',
                        );
                        launchUrl(
                          Uri.parse('https://wa.me/$intl?text=$hi'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              profileAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: LensLoader()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Could not load details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.8),
                      fontSize: 12.5,
                    ),
                  ),
                ),
                data: (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Payment details (how the owner pays this member) ──
                    if ((p.bkash ?? '').isNotEmpty ||
                        (p.bankDetails ?? '').isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.voidBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((p.bkash ?? '').isNotEmpty)
                              _payRow(
                                Icons.account_balance_wallet_outlined,
                                'bKash',
                                p.bkash!,
                              ),
                            if ((p.bkash ?? '').isNotEmpty &&
                                (p.bankDetails ?? '').isNotEmpty)
                              const SizedBox(height: 10),
                            if ((p.bankDetails ?? '').isNotEmpty)
                              _payRow(
                                Icons.account_balance_outlined,
                                'Bank',
                                p.bankDetails!,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // ── Gear ──
                    Text(
                      'GEAR',
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: AppColors.filmDim.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (p.gear.isEmpty)
                      Text(
                        'No gear added.',
                        style: TextStyle(
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                          fontSize: 12.5,
                        ),
                      )
                    else
                      for (final g in p.gear)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.camera_outlined,
                                size: 16,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  [
                                    g.name,
                                    if ((g.category ?? '').isNotEmpty)
                                      g.category!,
                                  ].join(' · '),
                                  style: TextStyle(
                                    color: AppColors.film,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12.5)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _payRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.8),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.film,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fetches the owner-visible member profile slice.
final _memberProfileProvider =
    FutureProvider.family<TeamMemberProfile, String>((ref, userId) {
      return ref.read(teamApiProvider).memberProfile(userId);
    });

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.loc, required this.ref});
  final AppLocalizations loc;
  final WidgetRef ref;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  String? _code;
  DateTime? _expiresAt;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(teamControllerProvider.notifier)
          .generateInviteCode();
      if (mounted) {
        setState(() {
          _code = result.code;
          _expiresAt = result.expiresAt;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.loc.team_invite_failed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        40 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.filmDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.loc.team_invite_member,
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.loc.team_invite_subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          if (_code != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.appBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _code!,
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      fontFamily: AppText.monoFontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.loc.team_invite_expires} ${_expiresAt != null ? '${_expiresAt!.hour}:${_expiresAt!.minute.toString().padLeft(2, '0')}' : ''}',
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(widget.loc.team_invite_done),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.film,
                        ),
                      )
                    : Text(widget.loc.team_generate_code),
              ),
            ),
            const SizedBox(height: 12),
            // Passcode-only joining (v15 rule): the owner shares this 6-digit
            // code and the freelancer joins with it — no email, no manual
            // entry. The email-invite path was removed per Heaven's request.
            Text(
              'Share this code — your teammate joins with it. '
              'No email needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
