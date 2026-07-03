// lib/features/bookings/presentation/widgets/delivery_checklist_sheet.dart
//
// Delivery checklist bottom sheet for a booking. Tracks the post-shoot
// deliverables a studio works through (backup → cull → edit → album →
// handover). The checked state is persisted on the booking itself, via
// BookingDetailController.updateDeliveryChecklist, which stores it inside the
// booking's clientRequirements JSON and rides the normal offline outbox to
// the server — so it works offline and survives a reinstall once synced.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

import '../../application/booking_detail_controller.dart';

/// The fixed set of delivery steps, in workflow order. Stored by stable key
/// so labels can be reworded later without losing saved state.
const _kChecklistSteps = <({String key, String label})>[
  (key: 'raw_backup', label: 'Raw files backed up'),
  (key: 'culled', label: 'Photos culled / selected'),
  (key: 'edited', label: 'Photos edited'),
  (key: 'album_designed', label: 'Album designed'),
  (key: 'album_printed', label: 'Album printed'),
  (key: 'online_delivered', label: 'Delivered online (Drive/link)'),
  (key: 'client_handover', label: 'Handed over to client'),
];

class DeliveryChecklistSheet extends ConsumerStatefulWidget {
  const DeliveryChecklistSheet({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<DeliveryChecklistSheet> createState() =>
      _DeliveryChecklistSheetState();
}

class _DeliveryChecklistSheetState
    extends ConsumerState<DeliveryChecklistSheet> {
  late Map<String, bool> _state;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _state = {for (final s in _kChecklistSteps) s.key: false};
  }

  void _hydrate(Map<String, dynamic>? requirements) {
    if (_loaded) return;
    final saved = requirements?['deliveryChecklist'];
    if (saved is Map) {
      for (final s in _kChecklistSteps) {
        final v = saved[s.key];
        if (v is bool) _state[s.key] = v;
      }
    }
    _loaded = true;
  }

  int get _doneCount => _state.values.where((v) => v).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(bookingDetailControllerProvider(widget.bookingId).notifier)
          .updateDeliveryChecklist(_state);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Delivery checklist saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save checklist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate once from the current envelope so reopening the sheet shows
    // the previously saved ticks.
    final envelope = ref
        .watch(bookingDetailControllerProvider(widget.bookingId))
        .value;
    _hydrate(envelope?.booking.clientRequirements);

    final total = _kChecklistSteps.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.filmMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Checklist',
                  style: TextStyle(
                    color: AppColors.film,
                    fontFamily: AppText.brandFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_doneCount / $total',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : _doneCount / total,
                minHeight: 6,
                backgroundColor: AppColors.glass,
                valueColor: AlwaysStoppedAnimation(AppColors.teal),
              ),
            ),
            const SizedBox(height: 12),
            for (final step in _kChecklistSteps)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.teal,
                value: _state[step.key] ?? false,
                onChanged: _saving
                    ? null
                    : (v) =>
                          setState(() => _state[step.key] = v ?? false),
                title: Text(
                  step.label,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onAccent,
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
