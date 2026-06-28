// lib/features/freelancer/presentation/fl_availability_screen.dart
//
// Freelancer Availability + Blackout Dates screen (FL-05).
// Layout:
//
//   ┌─────────────────────────────────────┐
//   │ AppBar: ← Availability             │
//   ├─────────────────────────────────────┤
//   │ Calendar grid (month view)          │
//   │   - Tap date → add blackout         │
//   │   - Blackout dates highlighted red  │
//   ├─────────────────────────────────────┤
//   │ Blackout list (upcoming)            │
//   │   BlackoutRow | BlackoutRow | ...   │
//   ├─────────────────────────────────────┤
//   │ FAB: + Add Blackout Date            │
//   └─────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/fl_tools_providers.dart';
import '../domain/fl_blackout_date.dart';

class FlAvailabilityScreen extends ConsumerStatefulWidget {
  const FlAvailabilityScreen({super.key});

  @override
  ConsumerState<FlAvailabilityScreen> createState() =>
      _FlAvailabilityScreenState();
}

class _FlAvailabilityScreenState extends ConsumerState<FlAvailabilityScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flBlackoutControllerProvider);

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
          'Availability',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () =>
            ref.read(flBlackoutControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CalendarHeader(
                focusedMonth: _focusedMonth,
                onPrevious: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
                onNext: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
              ),
            ),
            SliverToBoxAdapter(
              child: _CalendarGrid(
                focusedMonth: _focusedMonth,
                blackoutDates: async.valueOrNull ?? const [],
                onDateTap: _onDateTap,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'UPCOMING BLACKOUTS',
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: LensLoader()),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: 'Failed to load blackout dates.',
                  onRetry: () =>
                      ref.read(flBlackoutControllerProvider.notifier).refresh(),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message:
                          'No blackout dates set.\nTap a date on the calendar to mark unavailable.',
                      icon: Icons.event_busy_outlined,
                    ),
                  );
                }
                final sorted = List<FlBlackoutDate>.from(items)
                  ..sort((a, b) => a.date.compareTo(b.date));
                return SliverList.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => _BlackoutRow(
                    item: sorted[i],
                    onDelete: () => _confirmDelete(sorted[i]),
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => _onDateTap(DateTime.now()),
        icon: const Icon(Icons.add),
        label: Text('Add Blackout'),
      ),
    );
  }

  void _onDateTap(DateTime date) {
    _showAddBlackoutSheet(date);
  }

  void _showAddBlackoutSheet(DateTime initialDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _AddBlackoutSheet(
        initialDate: initialDate,
        onSubmit: (reason, endDate, recurrence) async {
          final now = DateTime.now();
          final draft = FlBlackoutDate(
            id: now.microsecondsSinceEpoch.toString(),
            freelancerId: '',
            date: initialDate,
            endDate: endDate,
            reason: reason.isEmpty ? null : reason,
            recurrence: recurrence,
            createdAt: now,
            updatedAt: now,
          );
          try {
            await ref.read(flBlackoutControllerProvider.notifier).add(draft);
            if (mounted) Navigator.of(context).pop();
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create blackout.')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(FlBlackoutDate item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: Text(
          'Remove Blackout?',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'This will make ${item.date.month}/${item.date.day} available again.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(flBlackoutControllerProvider.notifier).remove(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove blackout.')),
      );
    }
  }
}

// ─── Calendar Header ──────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focusedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppColors.filmDim),
            onPressed: onPrevious,
          ),
          Text(
            '${months[focusedMonth.month]} ${focusedMonth.year}',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppColors.filmDim),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.focusedMonth,
    required this.blackoutDates,
    required this.onDateTap,
  });

  final DateTime focusedMonth;
  final List<FlBlackoutDate> blackoutDates;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    final blackoutSet = {
      for (final b in blackoutDates)
        DateTime(b.date.year, b.date.month, b.date.day),
    };

    final cells = <Widget>[];
    for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              color: AppColors.filmMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      final isBlackout = blackoutSet.any(
        (b) =>
            b.year == date.year && b.month == date.month && b.day == date.day,
      );
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      cells.add(
        GestureDetector(
          onTap: () => onDateTap(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isBlackout
                  ? AppColors.red.withValues(alpha: 0.25)
                  : isToday
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isBlackout
                  ? Border.all(color: AppColors.red.withValues(alpha: 0.5))
                  : isToday
                  ? Border.all(color: AppColors.teal.withValues(alpha: 0.4))
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isBlackout
                    ? AppColors.red
                    : isToday
                    ? AppColors.teal
                    : AppColors.filmDim,
                fontSize: 13,
                fontWeight: isToday || isBlackout
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }
}

// ─── Blackout Row ─────────────────────────────────────────────────────

class _BlackoutRow extends StatelessWidget {
  const _BlackoutRow({required this.item, required this.onDelete});

  final FlBlackoutDate item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${item.date.month}/${item.date.day}/${item.date.year}';
    final endStr = item.endDate != null
        ? ' – ${item.endDate!.month}/${item.endDate!.day}/${item.endDate!.year}'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppColors.iconWrapDecoration(
              AppColors.red.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.event_busy_outlined,
              color: AppColors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateStr$endStr',
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.reason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.reason!,
                    style: TextStyle(
                      color: AppColors.filmMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (item.isRecurring) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Repeats ${item.recurrence.name}',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.filmMuted,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Add Blackout Sheet ───────────────────────────────────────────────

class _AddBlackoutSheet extends StatefulWidget {
  const _AddBlackoutSheet({required this.initialDate, required this.onSubmit});

  final DateTime initialDate;
  final Future<void> Function(
    String reason,
    DateTime? endDate,
    RecurrencePattern recurrence,
  )
  onSubmit;

  @override
  State<_AddBlackoutSheet> createState() => _AddBlackoutSheetState();
}

class _AddBlackoutSheetState extends State<_AddBlackoutSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  RecurrencePattern _recurrence = RecurrencePattern.none;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Blackout Date',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDateRow('Start Date', _startDate, (d) {
            setState(() => _startDate = d);
          }),
          const SizedBox(height: 12),
          _buildDateRow('End Date (optional)', _endDate, (d) {
            setState(() => _endDate = d);
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            style: TextStyle(color: AppColors.film),
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              hintStyle: TextStyle(color: AppColors.filmMuted),
              filled: true,
              fillColor: AppColors.voidElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RecurrencePattern>(
            initialValue: _recurrence,
            dropdownColor: AppColors.voidElevated,
            style: TextStyle(color: AppColors.film),
            decoration: InputDecoration(
              labelText: 'Recurrence',
              labelStyle: TextStyle(color: AppColors.filmMuted),
              filled: true,
              fillColor: AppColors.voidElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: RecurrencePattern.none,
                child: Text('None'),
              ),
              DropdownMenuItem(
                value: RecurrencePattern.weekly,
                child: Text('Weekly'),
              ),
              DropdownMenuItem(
                value: RecurrencePattern.biweekly,
                child: Text('Bi-weekly'),
              ),
              DropdownMenuItem(
                value: RecurrencePattern.monthly,
                child: Text('Monthly'),
              ),
              DropdownMenuItem(
                value: RecurrencePattern.yearly,
                child: Text('Yearly'),
              ),
            ],
            onChanged: (v) =>
                setState(() => _recurrence = v ?? RecurrencePattern.none),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      await widget.onSubmit(
                        _reasonController.text,
                        _endDate,
                        _recurrence,
                      );
                    },
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.film,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Save Blackout'),
            ),
          ),
        ],
      ),
    );
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
                  primary: AppColors.teal,
                  surface: AppColors.voidElevated,
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
          color: AppColors.voidElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
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
