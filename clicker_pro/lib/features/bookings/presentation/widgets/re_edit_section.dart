// lib/features/bookings/presentation/widgets/re_edit_section.dart
//
// Re-edit requests section on the booking detail screen. Two modes:
//
//   • Read-only — shows every existing request with round, status,
//     deadline, and an "overdue" badge for past-deadline rows.
//   • Editor    — exposes a "+ Request re-edit" button (gated by
//     `Capability.requestReEdit`) and per-row Start / Mark Done /
//     Reject affordances for the assigned editor (or any user with
//     `assignReEdit`, e.g. Owner / Both).
//
// Capability gating is centralized inside the section so the parent
// screen stays declarative — it just mounts the widget and the section
// figures out which controls are visible.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Re-edit Section". Validates Requirements 7.1–7.10, 11.6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/booking_status/booking_status.dart';
import '../../../../core/role/capability.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

import '../../application/booking_detail_controller.dart';
import '../../application/booking_providers.dart';
import '../../domain/booking.dart';
import '../../domain/re_edit_request.dart';
import '../../domain/re_edit_status.dart';
import 'detail_section.dart';
import 'lens_form_fields.dart';

/// Statuses for which a re-edit can legally be opened (Req 7.1).
const _kReEditEligibleStatuses = {
  BookingStatus.shotComplete,
  BookingStatus.delivered,
  BookingStatus.completed,
};

class ReEditSection extends ConsumerWidget {
  const ReEditSection({
    super.key,
    required this.booking,
    required this.requests,
  });

  final Booking booking;
  final List<ReEditRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    final canRequest =
        policy.can(Capability.requestReEdit) &&
        _kReEditEligibleStatuses.contains(booking.status);

    return DetailSection(
      title: 'Re-edit requests',
      actions: [
        if (canRequest)
          IconButton(
            tooltip: 'Request re-edit',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.orange,
            ),
            onPressed: () => _onRequest(context, ref),
          ),
      ],
      child: requests.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                canRequest
                    ? 'No re-edit requests yet. Tap "+" above to file one.'
                    : 'No re-edit requests yet.',
                style: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  _ReEditRow(request: requests[i]),
                  if (i != requests.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line(0.04),
                    ),
                ],
              ],
            ),
    );
  }

  Future<void> _onRequest(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reEditRepositoryProvider);
    final nextRound = await repo.nextRoundFor(booking.id);
    if (!context.mounted) return;
    final result = await _RequestReEditDialog.show(
      context: context,
      defaultRound: nextRound,
    );
    if (result == null) return;
    try {
      final session = ref.read(bookingsCurrentUserIdProvider);
      if (session == null) return;
      await repo.request(
        bookingId: booking.id,
        round: result.round,
        editorUserId: result.editorUserId,
        deadline: result.deadline,
        referenceImageUrls: null,
        notes: result.notes,
        requestedByUserId: session,
        policy: ref.read(bookingsPolicyProvider),
      );
      // Force a detail refresh so the new request appears immediately.
      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Re-edit request filed.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not file request: $e')));
    }
  }
}

class _ReEditRow extends ConsumerWidget {
  const _ReEditRow({required this.request});
  final ReEditRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(bookingsPolicyProvider);
    final currentUserId = ref.watch(bookingsCurrentUserIdProvider);
    final isAssignedEditor =
        currentUserId != null && currentUserId == request.editorUserId;
    final canManage = isAssignedEditor || policy.can(Capability.assignReEdit);

    final allowedTransitions = _allowedTransitions(request.status, canManage);
    final dateText = DateFormat.yMMMd().format(request.deadline);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Round ${request.round}',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(status: request.status),
                    if (request.isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 9,
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Deadline · $dateText',
                  style: TextStyle(
                    color: AppColors.filmMuted.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
                if ((request.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (allowedTransitions.isNotEmpty) ...[
            const SizedBox(width: 6),
            PopupMenuButton<ReEditStatus>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.filmMuted,
              ),
              color: AppColors.voidElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.line(0.08)),
              ),
              itemBuilder: (_) => [
                for (final s in allowedTransitions)
                  PopupMenuItem<ReEditStatus>(
                    value: s,
                    child: Text(
                      _menuLabel(s),
                      style: TextStyle(color: AppColors.film),
                    ),
                  ),
              ],
              onSelected: (toStatus) =>
                  _onTransition(context, ref, currentUserId, toStatus),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onTransition(
    BuildContext context,
    WidgetRef ref,
    String? currentUserId,
    ReEditStatus toStatus,
  ) async {
    if (currentUserId == null) return;
    try {
      await ref
          .read(reEditRepositoryProvider)
          .updateStatus(
            reEditId: request.id,
            toStatus: toStatus,
            policy: ref.read(bookingsPolicyProvider),
            currentUserId: currentUserId,
          );
      await ref
          .read(bookingDetailControllerProvider(request.bookingId).notifier)
          .refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Marked as ${toStatus.name}.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}

/// Allowed forward transitions for a re-edit request (Req 7.5).
List<ReEditStatus> _allowedTransitions(ReEditStatus from, bool canManage) {
  if (!canManage) return const [];
  switch (from) {
    case ReEditStatus.pending:
      return const [ReEditStatus.inProgress, ReEditStatus.rejected];
    case ReEditStatus.inProgress:
      return const [ReEditStatus.done, ReEditStatus.rejected];
    case ReEditStatus.done:
    case ReEditStatus.rejected:
      return const [];
  }
}

String _menuLabel(ReEditStatus s) {
  switch (s) {
    case ReEditStatus.inProgress:
      return 'Start';
    case ReEditStatus.done:
      return 'Mark Done';
    case ReEditStatus.rejected:
      return 'Reject';
    case ReEditStatus.pending:
      return 'Reopen';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ReEditStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: tone.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StatusTone {
  const _StatusTone({
    required this.background,
    required this.foreground,
    required this.border,
  });
  final Color background;
  final Color foreground;
  final Color border;
}

_StatusTone _toneFor(ReEditStatus s) {
  switch (s) {
    case ReEditStatus.pending:
      return _StatusTone(
        background: AppColors.indigo.withValues(alpha: 0.18),
        foreground: AppColors.indigo,
        border: AppColors.indigo.withValues(alpha: 0.45),
      );
    case ReEditStatus.inProgress:
      return _StatusTone(
        background: AppColors.orange.withValues(alpha: 0.18),
        foreground: AppColors.orange,
        border: AppColors.orange.withValues(alpha: 0.45),
      );
    case ReEditStatus.done:
      return _StatusTone(
        background: AppColors.green.withValues(alpha: 0.18),
        foreground: AppColors.green,
        border: AppColors.green.withValues(alpha: 0.45),
      );
    case ReEditStatus.rejected:
      return _StatusTone(
        background: AppColors.red.withValues(alpha: 0.18),
        foreground: AppColors.red,
        border: AppColors.red.withValues(alpha: 0.45),
      );
  }
}

/// Inline form for filing a fresh re-edit request. Returns a value
/// object the caller hands to `ReEditRepository.request`.
class _RequestReEditResult {
  const _RequestReEditResult({
    required this.round,
    required this.deadline,
    this.editorUserId,
    this.notes,
  });
  final int round;
  final DateTime deadline;
  final String? editorUserId;
  final String? notes;
}

class _RequestReEditDialog extends StatefulWidget {
  const _RequestReEditDialog({required this.defaultRound});
  final int defaultRound;

  static Future<_RequestReEditResult?> show({
    required BuildContext context,
    required int defaultRound,
  }) {
    return showDialog<_RequestReEditResult>(
      context: context,
      builder: (_) => _RequestReEditDialog(defaultRound: defaultRound),
    );
  }

  @override
  State<_RequestReEditDialog> createState() => _RequestReEditDialogState();
}

class _RequestReEditDialogState extends State<_RequestReEditDialog> {
  late final TextEditingController _editorCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _deadline;
  String? _deadlineError;

  @override
  void initState() {
    super.initState();
    _editorCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _editorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request re-edit (Round ${widget.defaultRound})',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: AppText.brandFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LensTextField(
              label: 'Editor user id (optional)',
              controller: _editorCtrl,
              hint: 'Leave blank to assign later',
            ),
            LensPickerRow(
              label: 'Deadline',
              icon: Icons.event_outlined,
              valueText: _deadline == null
                  ? null
                  : DateFormat.yMMMEd().format(_deadline!),
              placeholder: 'Pick a deadline',
              errorText: _deadlineError,
              onTap: _pickDeadline,
            ),
            LensTextField(
              label: 'Notes',
              controller: _notesCtrl,
              maxLines: 3,
              maxLength: 2000,
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
                    child: Text('File request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: AppColors.voidElevated,
            onSurface: AppColors.film,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.voidElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _deadline = picked;
      _deadlineError = null;
    });
  }

  void _onSubmit() {
    if (_deadline == null) {
      setState(() => _deadlineError = 'Pick a deadline.');
      return;
    }
    final editor = _editorCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    Navigator.of(context).pop(
      _RequestReEditResult(
        round: widget.defaultRound,
        deadline: _deadline!,
        editorUserId: editor.isEmpty ? null : editor,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }
}
