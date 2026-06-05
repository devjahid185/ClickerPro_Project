import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/reminder_providers.dart';
import '../domain/reminder.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReminderSheet(
        onSave: (draft) async {
          await ref.read(reminderListControllerProvider.notifier).add(draft);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reminderListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: AppColors.voidLight,
        onRefresh: () async {
          await ref.read(reminderListControllerProvider.notifier).refresh();
        },
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (_, _) => Center(
            child: ErrorState(
              message: 'Failed to load reminders',
              onRetry: () =>
                  ref.read(reminderListControllerProvider.notifier).refresh(),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.notifications_active_outlined,
                    message: 'No upcoming reminders',
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              itemBuilder: (_, i) => _ReminderRow(
                reminder: items[i],
                onDelete: () {
                  ref
                      .read(reminderListControllerProvider.notifier)
                      .remove(items[i].id);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Add Reminder Bottom Sheet ────────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.onSave});
  final Future<void> Function(Reminder draft) onSave;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  ReminderType _type = ReminderType.payment;
  ReminderChannel _channel = ReminderChannel.whatsapp;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final _bookingCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bookingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.film,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final draft = Reminder(
      id: '',
      bookingId: _bookingCtrl.text.trim(),
      type: _type,
      scheduledDate: _date,
      channel: _channel,
    );
    try {
      await widget.onSave(draft);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save reminder')),
        );
      }
    }
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.filmDim.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.filmMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Add Reminder',
            style: TextStyle(
              color: AppColors.film,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Type
          _label('TYPE'),
          const SizedBox(height: 6),
          Row(
            children: ReminderType.values.map((t) {
              final selected = _type == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: AppColors.orange,
                  backgroundColor: AppColors.voidLight,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.filmDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Channel
          _label('CHANNEL'),
          const SizedBox(height: 6),
          Row(
            children: ReminderChannel.values.map((c) {
              final selected = _channel == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => setState(() => _channel = c),
                  selectedColor: AppColors.teal,
                  backgroundColor: AppColors.voidLight,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.filmDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date
          _label('SCHEDULED DATE'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pick,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.voidLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.orange, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.film,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Booking ID (optional)
          _label('BOOKING ID (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _bookingCtrl,
            style: const TextStyle(color: AppColors.film, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. abc-123',
              hintStyle: TextStyle(
                  color: AppColors.filmMuted.withValues(alpha: 0.5),
                  fontSize: 13),
              filled: true,
              fillColor: AppColors.voidLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save Reminder',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminder Row ─────────────────────────────────────────────────────────────

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.onDelete});

  final Reminder reminder;
  final VoidCallback onDelete;

  IconData _typeIcon() {
    switch (reminder.type) {
      case ReminderType.payment:
        return Icons.payment_outlined;
      case ReminderType.delivery:
        return Icons.local_shipping_outlined;
      case ReminderType.feedback:
        return Icons.rate_review_outlined;
    }
  }

  Color _typeColor() {
    switch (reminder.type) {
      case ReminderType.payment:
        return AppColors.gold;
      case ReminderType.delivery:
        return AppColors.teal;
      case ReminderType.feedback:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();
    final dateStr =
        '${reminder.scheduledDate.year}-'
        '${reminder.scheduledDate.month.toString().padLeft(2, '0')}-'
        '${reminder.scheduledDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: AppColors.iconWrapDecoration(
            typeColor.withValues(alpha: 0.15),
          ),
          child: Icon(_typeIcon(), color: typeColor, size: 20),
        ),
        title: Text(
          reminder.type.name[0].toUpperCase() + reminder.type.name.substring(1),
          style: const TextStyle(
            color: AppColors.film,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$dateStr \u00b7 ${reminder.channel.name}',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reminder.sent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sent',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.filmMuted,
                size: 18,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
