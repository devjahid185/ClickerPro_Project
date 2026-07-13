// lib/features/admin/presentation/admin_landing_editor_screen.dart
//
// Edits the landing-site content (`landing.*` keys) and app links (`app.*`)
// stored in AppSetting. LandingController renders the live site from these
// same keys with the server defaults as fallback, so a save here changes
// deyalghori.com on the next page load — no deploy needed.
//
// The form is generic over whatever keys the API returns: new landing keys
// added on the backend show up here automatically. Empty field = use the
// server default (shown as the hint text).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/admin_providers.dart';
import '../domain/admin_setting.dart';

class AdminLandingEditorScreen extends ConsumerWidget {
  const AdminLandingEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        title: Text(
          'Landing Page',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (err, _) => ErrorState(
          message: 'Failed to load landing settings',
          onRetry: () => ref.invalidate(adminSettingsProvider),
        ),
        data: (groups) => _LandingForm(
          settings: [
            ...groups['landing'] ?? const <AdminSetting>[],
            ...groups['app'] ?? const <AdminSetting>[],
          ],
        ),
      ),
    );
  }
}

class _LandingForm extends ConsumerStatefulWidget {
  const _LandingForm({required this.settings});
  final List<AdminSetting> settings;

  @override
  ConsumerState<_LandingForm> createState() => _LandingFormState();
}

class _LandingFormState extends ConsumerState<_LandingForm> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  String? _error;

  /// Section header for a key, in display order. Keys that match no rule go
  /// under "Other" so nothing the backend adds later gets silently hidden.
  static const _sections = <(String, String)>[
    ('landing.hero_', 'Hero Section'),
    ('landing.feature_', 'Features Section'),
    ('landing.detail_mobile_', 'Card: Mobile App'),
    ('landing.detail_web_', 'Card: Web App'),
    ('landing.detail_team_', 'Card: Team & Roles'),
    ('landing.detail_finance_', 'Card: Built for BDT'),
    ('landing.review_1_', 'Review 1'),
    ('landing.review_2_', 'Review 2'),
    ('landing.review_3_', 'Review 3'),
    ('app.', 'App Links'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final s in widget.settings.where((s) => !s.isSecret))
        s.key: TextEditingController(text: s.value),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _sectionOf(String key) {
    for (final (prefix, title) in _sections) {
      if (key.startsWith(prefix)) return title;
    }
    return 'Other';
  }

  /// "landing.hero_title" → "Hero Title", "app.android_url" → "Android Url".
  String _labelOf(String key) {
    final tail = key.contains('.') ? key.split('.').last : key;
    return tail
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _save() async {
    final changes = <String, String>{};
    for (final s in widget.settings) {
      final ctrl = _controllers[s.key];
      if (ctrl != null && ctrl.text != s.value) {
        changes[s.key] = ctrl.text.trim();
      }
    }
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing changed.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminApiProvider).updateSettings(changes);
      ref.invalidate(adminSettingsProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${changes.length} change(s) — live on next page load.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save — please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Preserve API order inside each section; sections in declared order.
    final bySection = <String, List<AdminSetting>>{};
    for (final s in widget.settings.where((s) => !s.isSecret)) {
      bySection.putIfAbsent(_sectionOf(s.key), () => []).add(s);
    }
    final orderedSections = [
      for (final (_, title) in _sections)
        if (bySection.containsKey(title)) title,
      if (bySection.containsKey('Other')) 'Other',
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'These texts render the live landing site. Leave a field '
                  'empty to use the default (shown in grey).',
                  style: TextStyle(color: AppColors.filmDim, fontSize: 12.5, height: 1.5),
                ),
              ),
              for (final section in orderedSections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 10),
                  child: Text(
                    section,
                    style: TextStyle(
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                for (final s in bySection[section]!) ...[
                  TextField(
                    controller: _controllers[s.key],
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _labelOf(s.key),
                      hintText: s.defaultValue,
                      hintMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: AppColors.onAccent),
                      )
                    : const Text('Save & Publish'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
