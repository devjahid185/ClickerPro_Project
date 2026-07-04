// lib/features/bookings/presentation/widgets/distributor_panel.dart
//
// Distributor tools on the booking detail screen (Heaven feedback 2026-07).
//
// A distributor is a freelancer with Distribution mode ON (Settings) who
// takes bookings from owners and farms them out to other shooters. When
// such a freelancer opens an event they are assigned to, this panel lets
// them:
//
//   • add more crew — but ONLY in the role they were assigned as
//     (assigned as cinematographer → may add cinematographers only;
//     chiefPhotographer counts as photographer), picked from the studio's
//     team list;
//   • step aside — remove their own assignment after a replacement is in,
//     which is the "নিজে বদলি" flow.
//
// The server enforces the same two rules (AssignmentController), so this
// panel is a convenience surface, not the security boundary.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../application/booking_detail_controller.dart';
import '../../application/booking_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_role.dart';
import '../../domain/booking.dart';
import 'detail_section.dart';
import 'team_member_picker_sheet.dart';

/// Whether Distribution mode is enabled for [userId] (Settings toggle).
final _distributionEnabledProvider = FutureProvider.family<bool, String>(
  (ref, userId) => ref.read(preferencesRepositoryProvider)
      .getDistributionEnabled(userId),
);

class DistributorPanel extends ConsumerWidget {
  const DistributorPanel({
    super.key,
    required this.booking,
    required this.assignments,
    required this.currentUserId,
  });

  final Booking booking;
  final List<Assignment> assignments;
  final String currentUserId;

  /// The distributable role bucket: chief photographers hand out
  /// photographer slots.
  static AssignmentRole _bucket(AssignmentRole r) =>
      r == AssignmentRole.chiefPhotographer ? AssignmentRole.photographer : r;

  static String _label(AssignmentRole r) {
    switch (r) {
      case AssignmentRole.chiefPhotographer:
      case AssignmentRole.photographer:
        return 'Photographer';
      case AssignmentRole.cinematographer:
        return 'Cinematographer';
      case AssignmentRole.editor:
        return 'Editor';
      case AssignmentRole.assistant:
        return 'Assistant';
      case AssignmentRole.drone:
        return 'Drone Operator';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    if (policy.role != UserRole.freelancer) return const SizedBox.shrink();

    Assignment? own;
    for (final a in assignments) {
      if (a.userId == currentUserId) {
        own = a;
        break;
      }
    }
    if (own == null) return const SizedBox.shrink();

    final distributionOn =
        ref.watch(_distributionEnabledProvider(currentUserId)).valueOrNull ??
        false;
    if (!distributionOn) return const SizedBox.shrink();

    final role = _bucket(own.role);
    final roleLabel = _label(role);

    return DetailSection(
      title: 'Distribution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are assigned as ${_label(own.role)}. Add more '
            '${roleLabel.toLowerCase()}s to cover this event, or hand it '
            'over and step aside.',
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addCrew(context, ref, own!, role),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                  label: Text('Add $roleLabel'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _stepAside(context, ref, own!),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Step Aside'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(
                    color: AppColors.red.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addCrew(
    BuildContext context,
    WidgetRef ref,
    Assignment own,
    AssignmentRole role,
  ) async {
    final picked = await TeamMemberPickerSheet.show(
      context,
      title: 'Pick a ${_label(role).toLowerCase()}',
      excludedUserIds: assignments.map((a) => a.userId).toSet(),
      multiSelect: true,
      accentColor: AppColors.orange,
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(assignmentRepositoryProvider);
      final policy = ref.read(bookingsPolicyProvider);
      final now = DateTime.now();
      for (final member in picked) {
        await repo.add(
          Assignment(
            id: 'local_${now.microsecondsSinceEpoch}_${member.userId}',
            bookingId: booking.id,
            userId: member.userId,
            role: role,
            createdAt: now,
            updatedAt: now,
            pending: true,
          ),
          policy: policy,
        );
      }
      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${picked.length} ${_label(role).toLowerCase()}'
            '${picked.length > 1 ? 's' : ''} added.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add crew: $e')),
      );
    }
  }

  Future<void> _stepAside(
    BuildContext context,
    WidgetRef ref,
    Assignment own,
  ) async {
    final others = assignments.where((a) => a.userId != currentUserId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Step aside?',
          style: TextStyle(color: AppColors.film, fontSize: 18),
        ),
        content: Text(
          others.isEmpty
              ? 'No one else is assigned yet — add a replacement first so '
                    'the event is not left uncovered. Step aside anyway?'
              : 'Your assignment will be removed and the event stays with '
                    'the rest of the crew.',
          style: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Step Aside'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(assignmentRepositoryProvider)
          .remove(own.id, policy: ref.read(bookingsPolicyProvider));
      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('You have stepped aside.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not step aside: $e')),
      );
    }
  }
}
