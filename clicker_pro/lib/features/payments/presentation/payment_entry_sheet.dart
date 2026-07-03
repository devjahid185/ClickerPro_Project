// lib/features/payments/presentation/payment_entry_sheet.dart
//
// Modal bottom-sheet for recording a new payment. Uses the
// `PaymentEntrySheet.show()` static helper so callers don't need to
// know about the form key, controllers, or state wiring.
//
// Fields:
//   - Amount (required, > 0)
//   - Method: bKash / Bank / Cash with icons
//   - Type: Advance / Due / Extra
//   - Hide from team toggle
//
// Submit posts to `paymentListControllerProvider.add()` and propagates
// errors via SnackBar so the sheet stays open on failure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../application/payment_providers.dart';
import '../domain/payment_record.dart';
import '../../../theme/app_theme.dart';

class PaymentEntrySheet extends ConsumerStatefulWidget {
  const PaymentEntrySheet._({required this.eventId});

  final String eventId;

  static Future<PaymentRecord?> show(
    BuildContext context, {
    required String eventId,
  }) {
    return showModalBottomSheet<PaymentRecord?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentEntrySheet._(eventId: eventId),
      ),
    );
  }

  @override
  ConsumerState<PaymentEntrySheet> createState() => _PaymentEntrySheetState();
}

class _PaymentEntrySheetState extends ConsumerState<PaymentEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  String _method = 'cash';
  String _type = 'due';
  bool _hidden = false;
  bool _saving = false;
  // When the sheet is opened without a fixed event (the standalone Payments
  // screen passes ''), the owner picks which booking the payment applies to.
  String? _selectedEventId;

  /// The event this payment is recorded against — the fixed one passed in, or
  /// the booking the user picked.
  String get _effectiveEventId =>
      widget.eventId.isNotEmpty ? widget.eventId : (_selectedEventId ?? '');

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_effectiveEventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pick a booking for this payment first')),
      );
      return;
    }
    setState(() => _saving = true);

    final draft = PaymentRecord(
      id: '',
      eventId: _effectiveEventId,
      amount: double.parse(_amountCtl.text.trim()),
      method: _method,
      type: _type,
      hidden: _hidden,
      createdAt: DateTime.now(),
    );

    try {
      final saved = await ref
          .read(paymentListControllerProvider.notifier)
          .add(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      // Surface the real reason (validation / auth / network) — the generic
      // "Failed to save payment" hid the actual server error and made the
      // bug undiagnosable from the device.
      final reason = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save payment: $reason')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag-handle
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
              Text(
                'Record Payment',
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Booking picker — only when no fixed event was supplied.
              if (widget.eventId.isEmpty) ...[
                _buildBookingPicker(),
                const SizedBox(height: 16),
              ],

              // Amount
              TextFormField(
                controller: _amountCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(color: AppColors.film),
                decoration: _decoration('Amount'),
                validator: (raw) {
                  final v = double.tryParse((raw ?? '').trim());
                  if (v == null || v <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Method selector
              Text(
                'METHOD',
                style: TextStyle(
                  color: AppColors.filmDim,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _methodChip(
                    'bkash',
                    Icons.account_balance_wallet,
                    'bKash',
                    AppColors.purple,
                  ),
                  const SizedBox(width: 8),
                  _methodChip(
                    'bank',
                    Icons.account_balance,
                    'Bank',
                    AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  _methodChip(
                    'cash',
                    Icons.payments_outlined,
                    'Cash',
                    AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Type selector
              Text(
                'TYPE',
                style: TextStyle(
                  color: AppColors.filmDim,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _typeChip('advance', 'Advance'),
                  _typeChip('due', 'Due'),
                  _typeChip('extra', 'Extra'),
                ],
              ),
              const SizedBox(height: 16),

              // Hide from team toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.voidElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.filmDim,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hide from team',
                        style: TextStyle(color: AppColors.film, fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: _hidden,
                      onChanged: (v) => setState(() => _hidden = v),
                      activeThumbColor: AppColors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action row
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.filmDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const LensLoader(size: 18)
                          : Text('Save Payment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dropdown of the studio's bookings so a standalone payment can be
  /// attached to the right event. Uses the booking's server id (remoteId)
  /// because the payments API keys on the backend event id.
  Widget _buildBookingPicker() {
    final async = ref.watch(bookingListAllProvider(const BookingFilter()));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LensLoader(size: 20),
      ),
      error: (_, _) => Text(
        'Could not load bookings',
        style: TextStyle(color: AppColors.filmDim, fontSize: 13),
      ),
      data: (bookings) {
        // Only bookings already synced to the server can take a payment
        // (the API needs their backend id).
        final selectable = bookings
            .where((b) => (b.remoteId ?? '').isNotEmpty)
            .toList();
        if (selectable.isEmpty) {
          return Text(
            'No synced bookings to attach a payment to yet.',
            style: TextStyle(color: AppColors.filmDim, fontSize: 13),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOOKING',
              style: TextStyle(
                color: AppColors.filmDim,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedEventId,
              isExpanded: true,
              dropdownColor: AppColors.voidElevated,
              style: TextStyle(color: AppColors.film, fontSize: 14),
              decoration: _decoration('Select booking'),
              items: [
                for (final b in selectable)
                  DropdownMenuItem(
                    value: b.remoteId,
                    child: Text(
                      _bookingLabel(b),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Pick a booking' : null,
              onChanged: (v) => setState(() => _selectedEventId = v),
            ),
          ],
        );
      },
    );
  }

  String _bookingLabel(Booking b) {
    final who = (b.clientName?.trim().isNotEmpty ?? false)
        ? b.clientName!.trim()
        : b.title;
    final d = b.date;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '$who · $date';
  }

  Widget _methodChip(String value, IconData icon, String label, Color color) {
    final selected = _method == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColors.voidElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.filmDim, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.filmDim,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      selectedColor: AppColors.teal,
      backgroundColor: AppColors.voidElevated,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.filmDim),
      side: BorderSide(
        color: selected ? AppColors.teal : AppColors.glassBorder,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.filmDim),
      filled: true,
      fillColor: AppColors.voidElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.teal),
      ),
    );
  }
}
