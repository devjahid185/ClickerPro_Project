// lib/features/bookings/presentation/widgets/team_member_picker_sheet.dart
//
// Bottom-sheet picker that lists the owner's real team members
// (`GET /api/team/members`) with search + multi-select checkboxes.
// Replaces the old "paste a user ID" dialogs — manual ID entry was
// unusable and is removed per the v12 booking-form spec.
//
// Returns the selected members (empty list = user confirmed nothing,
// null = sheet dismissed). Members whose userId is in [excludedUserIds]
// are shown disabled so the same person can't be double-assigned.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/states/error_state.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../../team/application/team_providers.dart';
import '../../../team/domain/team_member.dart';
import 'lens_form_fields.dart';

class TeamMemberPickerSheet extends ConsumerStatefulWidget {
  const TeamMemberPickerSheet({
    super.key,
    required this.title,
    this.excludedUserIds = const <String>{},
    this.multiSelect = true,
    this.accentColor = AppColors.teal,
  });

  final String title;
  final Set<String> excludedUserIds;
  final bool multiSelect;
  final Color accentColor;

  static Future<List<TeamMember>?> show(
    BuildContext context, {
    required String title,
    Set<String> excludedUserIds = const <String>{},
    bool multiSelect = true,
    Color accentColor = AppColors.teal,
  }) {
    return showModalBottomSheet<List<TeamMember>>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => TeamMemberPickerSheet(
        title: title,
        excludedUserIds: excludedUserIds,
        multiSelect: multiSelect,
        accentColor: accentColor,
      ),
    );
  }

  @override
  ConsumerState<TeamMemberPickerSheet> createState() =>
      _TeamMemberPickerSheetState();
}

class _TeamMemberPickerSheetState extends ConsumerState<TeamMemberPickerSheet> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LensTextField(
              label: 'Search',
              controller: _searchCtrl,
              hint: 'Name, phone or email',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LensLoader(),
                ),
                error: (err, _) => ErrorState(
                  message: 'Could not load your team.',
                  onRetry: () => ref.invalidate(teamMembersProvider),
                ),
                data: (members) {
                  final filtered = members.where((m) {
                    if (_query.isEmpty) return true;
                    return m.fullName.toLowerCase().contains(_query) ||
                        m.email.toLowerCase().contains(_query) ||
                        (m.phone ?? '').toLowerCase().contains(_query);
                  }).toList();
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            color: AppColors.filmMuted.withValues(alpha: 0.85),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            members.isEmpty
                                ? 'No team members yet. Invite members from the Team screen first.'
                                : 'No members match your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.filmDim.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                    itemBuilder: (_, i) => _memberTile(filtered[i]),
                  );
                },
              ),
            ),
            if (widget.multiSelect) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _selectedUserIds.isEmpty
                      ? 'Add selected'
                      : 'Add ${_selectedUserIds.length} selected',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: AppColors.voidBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _selectedUserIds.isEmpty
                    ? null
                    : () {
                        final members = ref
                            .read(teamMembersProvider)
                            .valueOrNull;
                        if (members == null) return;
                        Navigator.of(context).pop(
                          members
                              .where(
                                (m) => _selectedUserIds.contains(m.userId),
                              )
                              .toList(),
                        );
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _memberTile(TeamMember m) {
    final alreadyAdded = widget.excludedUserIds.contains(m.userId);
    final selected = _selectedUserIds.contains(m.userId);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      enabled: !alreadyAdded,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: widget.accentColor.withValues(alpha: 0.15),
        backgroundImage: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
            ? NetworkImage(m.avatarUrl!)
            : null,
        child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
            ? Text(
                m.fullName.isEmpty ? '?' : m.fullName[0].toUpperCase(),
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Text(
        m.fullName.isEmpty ? m.email : m.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: alreadyAdded
              ? AppColors.filmMuted.withValues(alpha: 0.6)
              : AppColors.film,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        alreadyAdded
            ? 'Already added'
            : [
                if ((m.phone ?? '').isNotEmpty) m.phone!,
                _roleLabel(m.role),
              ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.filmDim.withValues(alpha: 0.8),
          fontSize: 11.5,
        ),
      ),
      trailing: widget.multiSelect
          ? Checkbox(
              value: selected,
              onChanged: alreadyAdded ? null : (_) => _toggle(m.userId),
              activeColor: widget.accentColor,
              checkColor: AppColors.voidBlack,
            )
          : Icon(
              Icons.chevron_right_rounded,
              color: AppColors.filmMuted,
            ),
      onTap: alreadyAdded
          ? null
          : widget.multiSelect
          ? () => _toggle(m.userId)
          : () => Navigator.of(context).pop(<TeamMember>[m]),
    );
  }

  void _toggle(String userId) {
    setState(() {
      if (!_selectedUserIds.remove(userId)) {
        _selectedUserIds.add(userId);
      }
    });
  }

  String _roleLabel(String wireRole) {
    final lower = wireRole.toLowerCase();
    if (lower.isEmpty) return 'Member';
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
