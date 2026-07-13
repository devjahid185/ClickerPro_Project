// lib/features/admin/presentation/widgets/app_control_tab.dart
//
// OTA update channel control for the studio mobile app. Backed by
// `GET /api/app/version` (public — every studio app polls it on launch) and
// `PATCH /api/admin/app/version` (AppVersionController::update, admin-only).
// Bumping versionCode here makes every installed studio app show its
// "Update available" dialog pointing at apkUrl — no Play Store involved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/states/error_state.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../application/admin_providers.dart';
import '../admin_landing_editor_screen.dart';

class AppControlTab extends ConsumerWidget {
  const AppControlTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAppVersionProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminAppVersionProvider.future),
      child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (err, _) => ListView(
          children: [
            const SizedBox(height: 120),
            ErrorState(
              message: 'Failed to load app version settings',
              onRetry: () => ref.invalidate(adminAppVersionProvider),
            ),
          ],
        ),
        data: (data) => _VersionForm(initial: data),
      ),
    );
  }
}

class _VersionForm extends ConsumerStatefulWidget {
  const _VersionForm({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_VersionForm> createState() => _VersionFormState();
}

class _VersionFormState extends ConsumerState<_VersionForm> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _notesCtrl;
  late bool _forceUpdate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _codeCtrl = TextEditingController(text: '${d['versionCode'] ?? ''}');
    _nameCtrl = TextEditingController(text: '${d['versionName'] ?? ''}');
    _urlCtrl = TextEditingController(text: '${d['apkUrl'] ?? ''}');
    _notesCtrl = TextEditingController(text: '${d['releaseNotes'] ?? ''}');
    _forceUpdate = d['forceUpdate'] == true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = int.tryParse(_codeCtrl.text.trim());
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (code == null || code < 1) {
      setState(() => _error = 'Version code must be a positive number.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Version name is required.');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _error = 'APK URL must be a valid link.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminApiProvider).updateAppVersion(
            versionCode: code,
            versionName: name,
            apkUrl: url,
            forceUpdate: _forceUpdate,
            releaseNotes: _notesCtrl.text.trim(),
          );
      ref.invalidate(adminAppVersionProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App update channel saved.')),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const AdminLandingEditorScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.language_outlined, color: AppColors.teal, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Landing Page',
                          style: TextStyle(
                            fontFamily: AppText.brandFontFamily,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.film,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Edit hero, features, reviews & links on the live site',
                          style: TextStyle(color: AppColors.filmDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.filmDim),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
          ),
          child: Text(
            'Every GRAPHY7 app checks these values on launch. '
            'Raise the version code to push an update prompt to all studios.',
            style: TextStyle(color: AppColors.filmDim, fontSize: 12.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Version Code'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Version Name',
                  hintText: '3.9.0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'APK Download URL',
            hintText: 'https://…/Graphy7.apk',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Release Notes (optional)',
            hintText: "What's new in this version",
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Force Update',
            style: TextStyle(
              color: _forceUpdate ? Colors.redAccent : AppColors.film,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Users cannot dismiss the update dialog',
            style: TextStyle(color: AppColors.filmDim, fontSize: 12),
          ),
          value: _forceUpdate,
          activeThumbColor: Colors.redAccent,
          onChanged: _saving ? null : (v) => setState(() => _forceUpdate = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        SizedBox(
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
                : const Text('Save Update Channel'),
          ),
        ),
      ],
    );
  }
}
