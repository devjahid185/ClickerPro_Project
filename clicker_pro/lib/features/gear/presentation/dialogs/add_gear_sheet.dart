// lib/features/gear/presentation/dialogs/add_gear_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../application/gear_providers.dart';
import '../../domain/gear_item.dart';
import '../../../../theme/app_theme.dart';

class AddGearSheet extends ConsumerStatefulWidget {
  const AddGearSheet._();

  static Future<GearItem?> show(BuildContext context) {
    return showModalBottomSheet<GearItem?>(
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
        child: const AddGearSheet._(),
      ),
    );
  }

  @override
  ConsumerState<AddGearSheet> createState() => _AddGearSheetState();
}

class _AddGearSheetState extends ConsumerState<AddGearSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _brandCtl = TextEditingController();
  final _valueCtl = TextEditingController();
  String? _category;
  String? _condition;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _brandCtl.dispose();
    _valueCtl.dispose();
    super.dispose();
  }

  List<({String key, String label})> _categories(AppLocalizations loc) => [
    (key: 'Camera', label: loc.gear_category_camera),
    (key: 'Lens', label: loc.gear_category_lens),
    (key: 'Flash', label: loc.gear_category_flash),
    (key: 'Tripod', label: loc.gear_category_tripod),
    (key: 'Drone', label: loc.gear_category_drone),
    (key: 'Audio', label: loc.gear_category_audio),
    (key: 'Lighting', label: loc.gear_category_lighting),
    (key: 'Storage', label: loc.gear_category_storage),
    (key: 'Other', label: loc.gear_category_other),
  ];

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final draft = GearItem(
      id: '',
      name: _nameCtl.text.trim(),
      brand: _brandCtl.text.trim().isEmpty ? null : _brandCtl.text.trim(),
      category: _category ?? 'Other',
      condition: _condition,
      value: double.tryParse(_valueCtl.text.trim()) ?? 0,
    );
    try {
      final saved = await ref
          .read(gearListControllerProvider.notifier)
          .add(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.gear_save_failed)));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cats = _categories(loc);
    final conditions = const ['New', 'Good', 'Fair', 'Repair'];

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
                loc.gear_add,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtl,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.gear_name),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.gear_validation_name_required
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtl,
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.gear_brand),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(color: AppColors.film),
                decoration: _decoration(loc.gear_value),
              ),
              const SizedBox(height: 12),
              Text(
                loc.gear_category,
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              const SizedBox(height: 6),
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
              Text(
                loc.gear_condition,
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in conditions)
                    ChoiceChip(
                      label: Text(c),
                      selected: _condition == c,
                      onSelected: (_) => setState(() => _condition = c),
                      selectedColor: AppColors.gold,
                      backgroundColor: AppColors.voidElevated,
                      labelStyle: TextStyle(
                        color: _condition == c
                            ? AppColors.voidBlack
                            : AppColors.filmDim,
                      ),
                      side: BorderSide(
                        color: _condition == c
                            ? AppColors.gold
                            : AppColors.glassBorder,
                      ),
                    ),
                ],
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
                        loc.gear_cancel,
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
                          : Text(loc.gear_save),
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
      borderSide: BorderSide(color: AppColors.orange),
    ),
  );
}
