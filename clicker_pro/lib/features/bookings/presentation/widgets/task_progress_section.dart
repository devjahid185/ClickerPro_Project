// lib/features/bookings/presentation/widgets/task_progress_section.dart
//
// Per-staff task progress on the booking detail screen. Two visibility
// rules:
//
//   • "My progress" — visible to anyone who has at least one assignment
//     on the booking. Edit-in-place via a slider (0–100, step 5) +
//     notes input (length 0–500). Persists through the existing
//     `TaskProgressRepository.upsert`, which routes through the outbox.
//
//   • "All progress" — visible to Owner / Both / Manager. Lists every
//     team member's row with name (placeholder uses user id until the
//     team-roster provider lands) + percentage + last note + last
//     touched-at.
//
// Bengali numerals are applied to percentage values via
// `BookingFormat.percent` when locale = bn.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Task Progress Section". Validates Requirements 8.1–8.7, 11.4.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../core/role/capability.dart';
import '../../../../features/settings/application/language_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../application/booking_providers.dart';
import '../../domain/assignment.dart';
import '../../domain/task_progress.dart';
import 'detail_section.dart';

class TaskProgressSection extends ConsumerStatefulWidget {
  const TaskProgressSection({
    super.key,
    required this.bookingId,
    required this.assignments,
    required this.taskProgress,
  });

  final String bookingId;
  final List<Assignment> assignments;
  final List<TaskProgress> taskProgress;

  @override
  ConsumerState<TaskProgressSection> createState() =>
      _TaskProgressSectionState();
}

class _TaskProgressSectionState extends ConsumerState<TaskProgressSection> {
  bool _editing = false;
  int _draftPercentage = 0;
  String _draftNote = '';
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(bookingsPolicyProvider);
    final currentUserId = ref.watch(bookingsCurrentUserIdProvider);
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');

    final hasOwnAssignment =
        currentUserId != null &&
        widget.assignments.any((a) => a.userId == currentUserId);

    final ownProgress = currentUserId == null
        ? null
        : widget.taskProgress
              .where((t) => t.userId == currentUserId)
              .cast<TaskProgress?>()
              .firstWhere((_) => true, orElse: () => null);

    final canViewAll =
        policy.role == UserRole.owner ||
        policy.role == UserRole.both ||
        policy.role == UserRole.manager;
    final othersProgress = currentUserId == null
        ? widget.taskProgress
        : widget.taskProgress
              .where((t) => t.userId != currentUserId)
              .toList(growable: false);

    return Column(
      children: [
        if (hasOwnAssignment && policy.can(Capability.updateTaskProgress))
          _buildMyProgress(context, lang, ownProgress),
        if (canViewAll && othersProgress.isNotEmpty)
          _buildAllProgress(context, lang, othersProgress),
      ],
    );
  }

  Widget _buildMyProgress(
    BuildContext context,
    String lang,
    TaskProgress? own,
  ) {
    return DetailSection(
      title: 'My progress',
      actions: [
        if (!_editing)
          TextButton(
            onPressed: () => _enterEdit(own),
            child: Text(
              own == null ? 'SET' : 'UPDATE',
              style: const TextStyle(
                color: AppColors.orange,
                fontFamily: 'Montserrat',
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
      child: _editing ? _buildEditor(context, lang) : _buildOwnRead(lang, own),
    );
  }

  Widget _buildOwnRead(String lang, TaskProgress? own) {
    if (own == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Tap UPDATE to log how far along you are.',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.7),
            fontSize: 12.5,
          ),
        ),
      );
    }
    final pct = own.percentage.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                BookingFormat.percent(
                  pct,
                  lang: lang,
                  bnNumerals: lang == 'bn',
                ),
                style: const TextStyle(
                  color: AppColors.film,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if ((own.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              own.note!,
              style: TextStyle(
                color: AppColors.film.withValues(alpha: 0.9),
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _draftPercentage.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20, // step 5
                  activeColor: AppColors.orange,
                  inactiveColor: Colors.black.withValues(alpha: 0.08),
                  label: '$_draftPercentage%',
                  onChanged: (v) =>
                      setState(() => _draftPercentage = v.round()),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  BookingFormat.percent(
                    _draftPercentage,
                    lang: lang,
                    bnNumerals: lang == 'bn',
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppColors.film, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Optional note',
              hintStyle: TextStyle(
                color: AppColors.filmMuted.withValues(alpha: 0.7),
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.orange),
              ),
            ),
            onChanged: (v) => _draftNote = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.filmDim),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _onSave,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllProgress(
    BuildContext context,
    String lang,
    List<TaskProgress> rows,
  ) {
    return DetailSection(
      title: 'Team progress',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _AllProgressRow(progress: rows[i], lang: lang),
            if (i != rows.length - 1)
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

  void _enterEdit(TaskProgress? own) {
    setState(() {
      _draftPercentage = own?.percentage.clamp(0, 100) ?? 0;
      _draftNote = own?.note ?? '';
      _noteCtrl.text = _draftNote;
      _editing = true;
    });
  }

  Future<void> _onSave() async {
    final currentUserId = ref.read(bookingsCurrentUserIdProvider);
    if (currentUserId == null) return;
    try {
      await ref
          .read(taskProgressRepositoryProvider)
          .upsert(
            bookingId: widget.bookingId,
            userId: currentUserId,
            percentage: _draftPercentage,
            note: _draftNote.trim().isEmpty ? null : _draftNote.trim(),
            policy: ref.read(bookingsPolicyProvider),
          );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save progress: $e')));
    }
  }
}

class _AllProgressRow extends StatelessWidget {
  const _AllProgressRow({required this.progress, required this.lang});
  final TaskProgress progress;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final pct = progress.percentage.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
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
              size: 14,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ${progress.userId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.film,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                  ),
                ),
                if ((progress.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    progress.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            BookingFormat.percent(pct, lang: lang, bnNumerals: lang == 'bn'),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
