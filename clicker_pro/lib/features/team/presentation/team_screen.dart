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

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final membersAsync = ref.watch(teamMembersProvider);

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
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Join a team with code',
            icon: Icon(Icons.key_outlined, color: AppColors.teal),
            onPressed: () => _showJoinSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: AppColors.gold),
            onPressed: () => _showInviteSheet(context, ref),
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
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    _TeamStatsStrip(members: members),
                    const SizedBox(height: 16),
                    _sectionLabel('ALL MEMBERS', members.length),
                    const SizedBox(height: 10),
                    for (var i = 0; i < members.length; i++) ...[
                      _TeamMemberTile(member: members[i]),
                      if (i != members.length - 1) const SizedBox(height: 8),
                    ],
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

/// Small uppercase section label with a count chip, matching the
/// Clicker Team layout.
Widget _sectionLabel(String text, int count) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
          color: AppColors.filmDim.withValues(alpha: 0.85),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

/// Stats strip — total members + role breakdown, themed in orange.
class _TeamStatsStrip extends StatelessWidget {
  const _TeamStatsStrip({required this.members});
  final List<TeamMember> members;

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final photographers = members
        .where((m) => m.role.toUpperCase().contains('PHOTO'))
        .length;
    final others = total - photographers;

    Widget cell(String value, String label, Color tint) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: tint,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.filmMuted,
            ),
          ),
        ],
      ),
    );

    Widget divider() => Container(
      width: 1,
      height: 34,
      color: AppColors.hairline,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          cell('$total'.padLeft(2, '0'), 'MEMBERS', AppColors.orange),
          divider(),
          cell('$photographers'.padLeft(2, '0'), 'PHOTO', AppColors.film),
          divider(),
          cell('$others'.padLeft(2, '0'), 'OTHERS', AppColors.gold),
        ],
      ),
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
              fontFamily: 'Poppins',
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
              color: AppColors.teal,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              fontFamily: 'Montserrat',
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '······',
              hintStyle: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.4),
                letterSpacing: 10,
              ),
              filled: true,
              fillColor: AppColors.voidBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _join,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.voidBlack,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final roleLabel = member.role.toLowerCase();
    final roleDisplay = roleLabel[0].toUpperCase() + roleLabel.substring(1);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showMemberProfile(context, ref),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.orange,
                  AppColors.orangeLight,
                ],
              ),
              border: Border.all(color: AppColors.glassBorder, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              member.fullName.isNotEmpty
                  ? member.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Only the teammate's display name is shown — email and other
            // personal identifiers are intentionally hidden in the team list.
            child: Text(
              member.fullName,
              style: TextStyle(
                color: AppColors.film,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              roleDisplay,
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                  backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                  backgroundImage:
                      (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                      ? Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.teal,
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
                    fontFamily: 'Poppins',
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
                      color: AppColors.teal,
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
                        fontFamily: 'Montserrat',
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
                                color: AppColors.teal,
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
              fontFamily: 'Poppins',
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
                color: AppColors.voidBlack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _code!,
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      fontFamily: 'Montserrat',
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
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.voidBlack,
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
                  foregroundColor: Colors.white,
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
