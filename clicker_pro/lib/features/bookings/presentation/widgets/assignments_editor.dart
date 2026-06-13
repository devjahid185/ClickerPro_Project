// lib/features/bookings/presentation/widgets/assignments_editor.dart
//
// Editable assignments list for the booking edit screen. Differs from
// `AssignmentsSection` (the read-only section on the detail screen) in
// three ways:
//
//   1. Per-row Edit / Remove affordances (Owner / Both / Manager).
//   2. An "Add row" button that opens a small inline editor sheet.
//   3. Renders even when the list is empty (with a "no assignments
//      yet" placeholder + Add button).
//
// All mutations write through `BookingEditController` so the parent
// form's dirty-tracking + save flow stays the source of truth. Final
// persistence happens at `controller.save()` time via the diff against
// the original snapshot — see the controller for details.
//
// Visibility rules:
//   • Hidden entirely when the role lacks `editAssignment`.
//   • Each row's payout column is gated by `showPayout` (Property 3).
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "AssignmentsEditor". Validates Requirements 2.9, 11.4, 11.6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../core/role/capability.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/application/language_controller.dart';
import '../../../team/application/team_providers.dart';
import '../../application/booking_edit_controller.dart';
import '../../application/booking_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_role.dart';
import 'detail_section.dart';
import 'lens_form_fields.dart';
import 'team_member_picker_sheet.dart';

class AssignmentsEditor extends ConsumerWidget {
  const AssignmentsEditor({
    super.key,
    required this.draft,
    required this.bookingId,
    required this.showPayout,
  });

  /// Family key passed to the edit controller so we can mutate the
  /// right draft. When the screen is in create-mode the bookingId is
  /// `null`; we forward that through.
  final String? bookingId;
  final BookingDraft draft;
  final bool showPayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    if (!policy.can(Capability.editAssignment)) {
      // Hide the entire section for roles without the capability —
      // they can still see assignments on the read-only detail screen.
      return const SizedBox.shrink();
    }

    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');
    final controller = ref.read(
      bookingEditControllerProvider(bookingId).notifier,
    );

    return DetailSection(
      title: 'Assignments',
      actions: [
        IconButton(
          tooltip: 'Add assignment',
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.orange,
          ),
          onPressed: () => _onAdd(context, controller),
        ),
      ],
      child: draft.assignments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No assignments yet. Tap "+" above to add one.',
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < draft.assignments.length; i++) ...[
                  _AssignmentRow(
                    assignment: draft.assignments[i],
                    showPayout: showPayout,
                    lang: lang,
                    onEdit: () =>
                        _onEdit(context, controller, draft.assignments[i]),
                    onRemove: () =>
                        controller.removeAssignment(draft.assignments[i].id),
                  ),
                  if (i != draft.assignments.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                ],
              ],
            ),
    );
  }

  Future<void> _onAdd(
    BuildContext context,
    BookingEditController controller,
  ) async {
    // Member is picked from the real team list — manual user-ID entry
    // was removed (non-coders can't know internal ids).
    final picked = await TeamMemberPickerSheet.show(
      context,
      title: 'Pick a team member',
      excludedUserIds: draft.assignments.map((a) => a.userId).toSet(),
      multiSelect: false,
      accentColor: AppColors.orange,
    );
    if (picked == null || picked.isEmpty) return;
    if (!context.mounted) return;
    final result = await _AssignmentEditDialog.show(
      context: context,
      userId: picked.first.userId,
      memberName: picked.first.fullName,
    );
    if (result == null) return;
    controller.addAssignment(
      userId: result.userId,
      role: result.role,
      payout: result.payout,
      notes: result.notes,
    );
  }

  Future<void> _onEdit(
    BuildContext context,
    BookingEditController controller,
    Assignment current,
  ) async {
    final result = await _AssignmentEditDialog.show(
      context: context,
      initial: current,
      userId: current.userId,
    );
    if (result == null) return;
    controller.updateAssignment(
      current.id,
      userId: result.userId,
      role: result.role,
      payout: result.payout,
      notes: result.notes,
    );
  }
}

class _AssignmentRow extends ConsumerWidget {
  const _AssignmentRow({
    required this.assignment,
    required this.showPayout,
    required this.lang,
    required this.onEdit,
    required this.onRemove,
  });

  final Assignment assignment;
  final bool showPayout;
  final String lang;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the team member's real name; fall back to the raw id only
    // when the member list hasn't loaded or the user left the team.
    final members = ref.watch(teamMembersProvider).valueOrNull;
    final memberName = members
        ?.where((m) => m.userId == assignment.userId)
        .firstOrNull
        ?.fullName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName ?? 'User ${assignment.userId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  assignment.role.name,
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          if (showPayout) ...[
            const SizedBox(width: 8),
            Text(
              BookingFormat.money(
                assignment.payout,
                lang: lang,
                bnNumerals: lang == 'bn',
              ),
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.gold,
              size: 18,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
              size: 18,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Dialog return value — the screen-level controller maps these fields
/// onto its add / update calls.
class _AssignmentEditResult {
  const _AssignmentEditResult({
    required this.userId,
    required this.role,
    required this.payout,
    this.notes,
  });
  final String userId;
  final AssignmentRole role;
  final double payout;
  final String? notes;
}

class _AssignmentEditDialog extends StatefulWidget {
  const _AssignmentEditDialog({
    this.initial,
    required this.userId,
    this.memberName,
  });
  final Assignment? initial;
  final String userId;
  final String? memberName;

  static Future<_AssignmentEditResult?> show({
    required BuildContext context,
    required String userId,
    Assignment? initial,
    String? memberName,
  }) {
    return showDialog<_AssignmentEditResult>(
      context: context,
      builder: (_) => _AssignmentEditDialog(
        initial: initial,
        userId: userId,
        memberName: memberName,
      ),
    );
  }

  @override
  State<_AssignmentEditDialog> createState() => _AssignmentEditDialogState();
}

class _AssignmentEditDialogState extends State<_AssignmentEditDialog> {
  late final TextEditingController _payoutCtrl;
  late final TextEditingController _notesCtrl;
  late AssignmentRole _role;

  String? _payoutError;

  @override
  void initState() {
    super.initState();
    _payoutCtrl = TextEditingController(
      text: widget.initial?.payout.toStringAsFixed(0) ?? '0',
    );
    _notesCtrl = TextEditingController(text: widget.initial?.notes ?? '');
    _role = widget.initial?.role ?? AssignmentRole.photographer;
  }

  @override
  void dispose() {
    _payoutCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit assignment' : 'Add assignment',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.memberName != null && widget.memberName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.memberName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.film,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            LensSelector<AssignmentRole>(
              label: 'Role',
              value: _role,
              items: AssignmentRole.values,
              itemLabel: (r) => _titleCase(r.name),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _role = v);
              },
            ),
            LensTextField(
              label: 'Payout',
              controller: _payoutCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _payoutError,
              onChanged: (_) => _clearErrors(),
            ),
            LensTextField(
              label: 'Notes (optional)',
              controller: _notesCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.filmDim),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onSubmit,
                    child: Text(isEdit ? 'Save' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearErrors() {
    if (_payoutError != null) {
      setState(() => _payoutError = null);
    }
  }

  void _onSubmit() {
    final payoutText = _payoutCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final payout = double.tryParse(payoutText);
    String? payoutErr;
    if (payout == null) {
      payoutErr = 'Payout must be a number.';
    } else if (payout < 0) {
      payoutErr = 'Payout must be ≥ 0.';
    }
    if (payoutErr != null) {
      setState(() => _payoutError = payoutErr);
      return;
    }
    Navigator.of(context).pop(
      _AssignmentEditResult(
        userId: widget.userId,
        role: _role,
        payout: payout!,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }
}

String _titleCase(String input) {
  if (input.isEmpty) return input;
  final spaced = input.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  return spaced
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}
