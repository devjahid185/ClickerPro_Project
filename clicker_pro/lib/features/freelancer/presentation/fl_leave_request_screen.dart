// lib/features/freelancer/presentation/fl_leave_request_screen.dart
//
// Freelancer Leave Request form screen (FL-07).
// Formal leave request with reason, date range, and notes.
// Owner notification → approve → auto blackout.
//
// Layout:
//
//   ┌─────────────────────────────────────┐
//   │ AppBar: ← Leave Request            │
//   ├─────────────────────────────────────┤
//   │ Existing requests list (top)        │
//   ├─────────────────────────────────────┤
//   │ Form section                       │
//   │   Date range picker                │
//   │   Reason dropdown                  │
//   │   Notes textarea                   │
//   │   [Submit Request] button          │
//   └─────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/fl_tools_providers.dart';
import '../domain/fl_leave_request.dart';
import '../../../theme/app_theme.dart';

class FlLeaveRequestScreen extends ConsumerStatefulWidget {
  const FlLeaveRequestScreen({super.key});

  @override
  ConsumerState<FlLeaveRequestScreen> createState() =>
      _FlLeaveRequestScreenState();
}

class _FlLeaveRequestScreenState extends ConsumerState<FlLeaveRequestScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _reason = 'Personal';
  final _notesController = TextEditingController();
  bool _submitting = false;

  static const _reasons = [
    'Personal',
    'Medical',
    'Family',
    'Travel',
    'Emergency',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flLeaveRequestControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Leave Request',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.surface,
        onRefresh: () =>
            ref.read(flLeaveRequestControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Existing Requests ──
            Row(
              children: [
                Container(width: 26, height: 1.5, color: AppColors.orange),
                const SizedBox(width: 10),
                Text(
                  'PAST REQUESTS',
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10,
                    letterSpacing: 0.16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            async.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => const SizedBox(
                height: 80,
                child: ErrorState(message: 'Failed to load requests.'),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line(0.06)),
                    ),
                    child: Text(
                      'No leave requests yet.',
                      style: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: items
                      .map((r) => _LeaveRequestRow(request: r))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── New Request Form ──
            Row(
              children: [
                Container(width: 26, height: 1.5, color: AppColors.orange),
                const SizedBox(width: 10),
                Text(
                  'NEW REQUEST',
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10,
                    letterSpacing: 0.16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date range
            _buildDateRow('Start Date', _startDate, (d) {
              setState(() => _startDate = d);
            }),
            const SizedBox(height: 10),
            _buildDateRow('End Date', _endDate, (d) {
              setState(() => _endDate = d);
            }),
            const SizedBox(height: 10),

            // Reason dropdown
            DropdownButtonFormField<String>(
              initialValue: _reason,
              dropdownColor: AppColors.surfaceAlt,
              style: TextStyle(color: AppColors.film),
              decoration: InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: AppColors.filmMuted),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line(0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line(0.06)),
                ),
              ),
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'Personal'),
            ),
            const SizedBox(height: 10),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(color: AppColors.film),
              decoration: InputDecoration(
                hintText: 'Additional notes (optional)',
                hintStyle: TextStyle(color: AppColors.filmMuted),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line(0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line(0.06)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.onAccent,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final draft = FlLeaveRequest(
        id: now.microsecondsSinceEpoch.toString(),
        freelancerId: '',
        ownerId: '',
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reason,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(flLeaveRequestControllerProvider.notifier).submit(draft);
      if (mounted) {
        setState(() {
          _startDate = null;
          _endDate = null;
          _reason = 'Personal';
          _notesController.clear();
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request submitted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request.')),
        );
      }
    }
  }

  Widget _buildDateRow(
    String label,
    DateTime? date,
    ValueChanged<DateTime> onChanged,
  ) {
    final display = date != null
        ? '${date.month}/${date.day}/${date.year}'
        : 'Select date';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.orange,
                  surface: AppColors.surfaceAlt,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.filmMuted, fontSize: 13),
            ),
            Text(
              display,
              style: TextStyle(
                color: date != null ? AppColors.film : AppColors.filmMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Request Row ────────────────────────────────────────────────

class _LeaveRequestRow extends StatelessWidget {
  const _LeaveRequestRow({required this.request});

  final FlLeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      LeaveRequestStatus.pending: AppColors.gold,
      LeaveRequestStatus.approved: AppColors.green,
      LeaveRequestStatus.denied: AppColors.red,
      LeaveRequestStatus.cancelled: AppColors.filmMuted,
    };
    final color = statusColors[request.status] ?? AppColors.filmMuted;
    final startStr = '${request.startDate.month}/${request.startDate.day}';
    final endStr = '${request.endDate.month}/${request.endDate.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppColors.iconWrapDecoration(
              color.withValues(alpha: 0.14),
            ),
            child: Icon(
              request.status == LeaveRequestStatus.approved
                  ? Icons.check_circle_outline
                  : request.status == LeaveRequestStatus.denied
                  ? Icons.cancel_outlined
                  : Icons.schedule,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startStr – $endStr  ·  ${request.durationDays} day${request.durationDays > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.reason,
                  style: TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: AppColors.pillChipDecoration(
              tint: color.withValues(alpha: 0.15),
            ),
            child: Text(
              request.status.name.toUpperCase(),
              style: TextStyle(
                color: color,
                fontFamily: AppText.monoFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
