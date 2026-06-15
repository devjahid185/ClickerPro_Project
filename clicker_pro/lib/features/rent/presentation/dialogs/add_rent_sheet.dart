// lib/features/rent/presentation/dialogs/add_rent_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/rent_providers.dart';
import '../../domain/rent_record.dart';

class AddRentSheet extends ConsumerStatefulWidget {
  const AddRentSheet._();

  static Future<RentRecord?> show(BuildContext context) {
    return showModalBottomSheet<RentRecord?>(
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
        child: const AddRentSheet._(),
      ),
    );
  }

  @override
  ConsumerState<AddRentSheet> createState() => _AddRentSheetState();
}

class _AddRentSheetState extends ConsumerState<AddRentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  RentDirection _direction = RentDirection.out_;
  DateTime? _returnBy;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnBy ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.orange,
            surface: AppColors.voidLight,
            onSurface: AppColors.film,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _returnBy = picked);
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final draft = RentRecord(
      id: '',
      direction: _direction,
      counterpartyName: _nameCtl.text.trim(),
      counterpartyPhone: _phoneCtl.text.trim().isEmpty
          ? null
          : _phoneCtl.text.trim(),
      amount: double.tryParse(_amountCtl.text.trim()) ?? 0,
      returnBy: _returnBy,
      status: RentStatus.active,
    );
    try {
      final saved = await ref
          .read(rentHistoryControllerProvider.notifier)
          .create(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.rent_save_failed)));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
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
              Text(
                loc.rent_add,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Direction toggle
              Text(
                loc.rent_direction,
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              const SizedBox(height: 6),
              SegmentedButton<RentDirection>(
                segments: [
                  ButtonSegment(
                    value: RentDirection.out_,
                    label: Text(loc.rent_direction_out),
                    icon: const Icon(Icons.upload_outlined),
                  ),
                  ButtonSegment(
                    value: RentDirection.in_,
                    label: Text(loc.rent_direction_in),
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() => _direction = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.voidElevated,
                  foregroundColor: AppColors.filmDim,
                  selectedBackgroundColor: AppColors.orange,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtl,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.rent_counterparty_name),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.rent_validation_name_required
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.rent_counterparty_phone),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.rent_amount),
              ),
              const SizedBox(height: 12),

              // Return-by date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.voidElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _returnBy == null
                              ? loc.rent_return_by
                              : '${loc.rent_return_by}: '
                                    '${_returnBy!.year}-'
                                    '${_returnBy!.month.toString().padLeft(2, '0')}-'
                                    '${_returnBy!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppColors.film),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.filmMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        loc.rent_cancel,
                        style: TextStyle(color: AppColors.filmDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const LensLoader(size: 18)
                          : Text(loc.rent_save),
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

  InputDecoration _decoration(String label) => InputDecoration(
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
      borderSide: const BorderSide(color: AppColors.orange),
    ),
  );
}
