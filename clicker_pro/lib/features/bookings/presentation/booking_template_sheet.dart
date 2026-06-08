import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../domain/booking_template.dart';
import '../domain/event_type.dart';
import '../domain/shift.dart';

class _TemplateNotifier extends AsyncNotifier<List<BookingTemplate>> {
  static const _key = 'booking_templates_v1';

  @override
  Future<List<BookingTemplate>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BookingTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<BookingTemplate> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(BookingTemplate t) async {
    final current = state.valueOrNull ?? [];
    final next = [...current, t];
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? [];
    final next = [for (final t in current) if (t.id != id) t];
    state = AsyncData(next);
    await _save(next);
  }
}

final bookingTemplateListProvider =
    AsyncNotifierProvider<_TemplateNotifier, List<BookingTemplate>>(
      _TemplateNotifier.new,
    );

class BookingTemplateSheet extends ConsumerStatefulWidget {
  const BookingTemplateSheet._();

  static Future<BookingTemplate?> show(BuildContext context) {
    return showModalBottomSheet<BookingTemplate?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const BookingTemplateSheet._(),
    );
  }

  @override
  ConsumerState<BookingTemplateSheet> createState() =>
      _BookingTemplateSheetState();
}

class _BookingTemplateSheetState extends ConsumerState<BookingTemplateSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(bookingTemplateListProvider).valueOrNull ?? [];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.filmMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Booking Templates',
                      style: TextStyle(
                        color: AppColors.film,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.filmDim),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (templates.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: templates.length,
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: AppColors.glassCardDecoration(),
                      child: ListTile(
                        title: Text(
                          t.name,
                          style: const TextStyle(
                            color: AppColors.film,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${t.eventType.name} \u00b7 ${t.shift.name}',
                          style: TextStyle(
                            color: AppColors.filmDim.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.filmMuted,
                          size: 20,
                        ),
                        onTap: () => Navigator.of(context).pop(t),
                      ),
                    );
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: Text(
                    'No templates saved yet.\nSave a booking as a template to reuse it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.filmMuted, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.film),
                      decoration: InputDecoration(
                        hintText: 'Template name...',
                        hintStyle: const TextStyle(color: AppColors.filmMuted),
                        filled: true,
                        fillColor: AppColors.voidElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.teal),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () {
                            final name = _nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            setState(() => _saving = true);
                            final template = BookingTemplate(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: name,
                              eventType: EventType.other,
                              shift: Shift.day,
                            );
                            ref
                                .read(bookingTemplateListProvider.notifier)
                                .add(template);
                            _nameCtrl.clear();
                            setState(() => _saving = false);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
