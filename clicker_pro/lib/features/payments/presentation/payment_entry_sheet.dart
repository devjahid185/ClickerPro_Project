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

import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/payment_providers.dart';
import '../domain/payment_record.dart';

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

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final draft = PaymentRecord(
      id: '',
      eventId: widget.eventId,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save payment')));
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
              const Text(
                'Record Payment',
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: const TextStyle(color: AppColors.film),
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
              const Text(
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
              const Text(
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
                    const Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.filmDim,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
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
                      child: const Text(
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
                          : const Text('Save Payment'),
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
      labelStyle: const TextStyle(color: AppColors.filmDim),
      filled: true,
      fillColor: AppColors.voidElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal),
      ),
    );
  }
}
