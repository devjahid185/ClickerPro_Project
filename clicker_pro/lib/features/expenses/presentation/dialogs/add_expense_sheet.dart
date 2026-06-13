// lib/features/expenses/presentation/dialogs/add_expense_sheet.dart
//
// Modal bottom-sheet for recording a new expense.  Uses the
// `AddExpenseSheet.show()` static helper so callers don't need to know
// about the Form key, controllers, or validator wiring।
//
// Validation:
//   - amount: required, > 0, parsed as double
//   - category: required, picked from a chip selector + custom-string
//     fallback when the user types into the "Other" slot
//
// Submit posts to `expenseListControllerProvider.add()` and propagates
// errors via SnackBar so the sheet stays open on failure।

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/expense_providers.dart';
import '../../domain/expense.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet._();

  static Future<Expense?> show(BuildContext context) {
    return showModalBottomSheet<Expense?>(
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
        child: const AddExpenseSheet._(),
      ),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  String? _category;
  DateTime _incurredAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  /// Categories — keys map to ARB strings so the chip label localizes,
  /// but the actual stored value is the canonical English label so the
  /// backend's category column stays stable across locales।
  List<({String key, String label})> _categories(AppLocalizations loc) => [
    (key: 'Travel', label: loc.expenses_category_travel),
    (key: 'Equipment', label: loc.expenses_category_equipment),
    (key: 'Software', label: loc.expenses_category_software),
    (key: 'Salary', label: loc.expenses_category_salary),
    (key: 'Marketing', label: loc.expenses_category_marketing),
    (key: 'Studio', label: loc.expenses_category_studio),
    (key: 'Food', label: loc.expenses_category_food),
    (key: 'Other', label: loc.expenses_category_other),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incurredAt,
      firstDate: DateTime(2000),
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
    if (picked != null) {
      setState(() => _incurredAt = picked);
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.expenses_validation_category_required)),
      );
      return;
    }
    setState(() => _saving = true);
    final draft = Expense(
      id: '', // server assigns
      category: _category!,
      amount: double.parse(_amountCtl.text.trim()),
      note: _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
      incurredAt: _incurredAt,
    );

    try {
      final saved = await ref
          .read(expenseListControllerProvider.notifier)
          .add(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.expenses_save_failed)));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cats = _categories(loc);

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
                loc.expenses_add,
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
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.expenses_amount),
                validator: (raw) {
                  final v = double.tryParse((raw ?? '').trim());
                  if (v == null || v <= 0) {
                    return loc.expenses_validation_amount_required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category chip selector
              Text(
                loc.expenses_category,
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
                  for (final c in cats)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c.key,
                      onSelected: (_) => setState(() => _category = c.key),
                      selectedColor: AppColors.orange,
                      backgroundColor: AppColors.voidElevated,
                      labelStyle: TextStyle(
                        color: _category == c.key
                            ? Colors.white
                            : AppColors.filmDim,
                      ),
                      side: BorderSide(
                        color: _category == c.key
                            ? AppColors.orange
                            : AppColors.glassBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Date picker
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
                          '${loc.expenses_incurred_on}: '
                          '${_incurredAt.year}-'
                          '${_incurredAt.month.toString().padLeft(2, '0')}-'
                          '${_incurredAt.day.toString().padLeft(2, '0')}',
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
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteCtl,
                maxLines: 2,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.expenses_note_optional),
              ),
              const SizedBox(height: 20),

              // Action row
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        loc.expenses_cancel,
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
                          : Text(loc.expenses_save),
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
        borderSide: const BorderSide(color: AppColors.orange),
      ),
    );
  }
}
