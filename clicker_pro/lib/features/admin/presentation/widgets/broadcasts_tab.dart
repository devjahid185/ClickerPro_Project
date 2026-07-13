// lib/features/admin/presentation/widgets/broadcasts_tab.dart
//
// List + create/edit/delete for platform broadcasts. Backed by
// `/api/admin/broadcasts` (BroadcastController::adminIndex/Store/Update/
// Destroy) — the same rows the studio app's read-only "Platform Updates"
// feed (features/broadcasts) displays.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/states/empty_state.dart';
import '../../../../shared/states/error_state.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../application/admin_providers.dart';
import '../../domain/admin_broadcast.dart';

class BroadcastsTab extends ConsumerWidget {
  const BroadcastsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminBroadcastsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // No FAB here — the shared floating nav in AdminHomeScreen owns the
      // center "+" action, which calls BroadcastsTab.openComposer directly.
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminBroadcastsProvider.future),
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              ErrorState(
                message: 'Failed to load broadcasts',
                onRetry: () => ref.invalidate(adminBroadcastsProvider),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.campaign_outlined,
                      message: 'No broadcasts yet.\nTap "New Broadcast" to publish one.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _BroadcastCard(broadcast: items[i]),
                ),
        ),
      ),
    );
  }

  /// Opens the create/edit broadcast sheet. Public + static so the shared
  /// floating nav's center "+" button in AdminHomeScreen can trigger a "new
  /// broadcast" flow without duplicating the composer.
  static void openComposer(BuildContext context, {AdminBroadcast? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BroadcastComposerSheet(existing: existing),
    );
  }
}

class _BroadcastCard extends ConsumerWidget {
  const _BroadcastCard({required this.broadcast});
  final AdminBroadcast broadcast;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete broadcast?'),
        content: Text('"${broadcast.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminApiProvider).deleteBroadcast(broadcast.id);
    ref.invalidate(adminBroadcastsProvider);
  }

  Future<void> _toggleActive(WidgetRef ref) async {
    await ref
        .read(adminApiProvider)
        .updateBroadcast(broadcast.id, isActive: !broadcast.isActive);
    ref.invalidate(adminBroadcastsProvider);
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BroadcastComposerSheet(existing: broadcast),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      broadcast.title,
                      style: TextStyle(
                        fontFamily: AppText.brandFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: AppColors.film,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: (broadcast.isActive ? AppColors.teal : AppColors.filmDim)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      broadcast.isActive ? 'ACTIVE' : 'ARCHIVED',
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: broadcast.isActive ? AppColors.teal : AppColors.filmDim,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                broadcast.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.filmDim, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: AppColors.filmDim),
                  const SizedBox(width: 4),
                  Text('${broadcast.viewCount}', style: TextStyle(color: AppColors.filmDim, fontSize: 12)),
                  const SizedBox(width: 14),
                  Icon(Icons.touch_app_outlined, size: 14, color: AppColors.filmDim),
                  const SizedBox(width: 4),
                  Text('${broadcast.clickCount}', style: TextStyle(color: AppColors.filmDim, fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _toggleActive(ref),
                    child: Text(broadcast.isActive ? 'Archive' : 'Activate'),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.filmDim),
                    onPressed: () => _openEditor(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _delete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadcastComposerSheet extends ConsumerStatefulWidget {
  const _BroadcastComposerSheet({this.existing});
  final AdminBroadcast? existing;

  @override
  ConsumerState<_BroadcastComposerSheet> createState() =>
      _BroadcastComposerSheetState();
}

class _BroadcastComposerSheetState extends ConsumerState<_BroadcastComposerSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _linkCtrl;
  String _priority = 'Normal';

  /// Call-to-action label shown on the broadcast button. Owner picks one of
  /// the common presets; the value is stored verbatim as `button_label`.
  String _buttonLabel = _ctaLabels.first;
  static const _ctaLabels = <String>[
    'Learn More',
    'Shop Now',
    'Buy Now',
    'Get Started',
    'Contact Us',
    'Download',
  ];
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _error;

  /// Newly picked file staged for upload on submit. `null` while nothing new
  /// has been picked — [_existingImageUrl] still shows if editing a
  /// broadcast that already has one.
  File? _pickedImage;
  String? _existingImageUrl;

  static const _priorities = ['Normal', 'Important', 'Emergency'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _linkCtrl = TextEditingController(text: e?.link ?? '');
    _existingImageUrl = e?.imageUrl;
    if (e != null && _priorities.contains(e.priority)) _priority = e.priority;
    // Restore the saved CTA label when editing; unknown / custom labels fall
    // back to the first preset so the dropdown always has a valid value.
    final existingLabel = e?.buttonLabel?.trim();
    if (existingLabel != null && _ctaLabels.contains(existingLabel)) {
      _buttonLabel = existingLabel;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _pickedImage = File(picked.path);
      _existingImageUrl = null; // the new pick replaces whatever was there
    });
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and message are required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = ref.read(adminApiProvider);
      final link = _linkCtrl.text.trim();

      // Upload the picked image first (if any) so its URL is ready to save
      // alongside the broadcast in one go.
      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        setState(() => _uploadingImage = true);
        imageUrl = await api.uploadImage(_pickedImage!.path);
        if (!mounted) return;
        setState(() => _uploadingImage = false);
      }

      // The CTA label only matters when there's a link to open; without one
      // the button never renders, so don't persist a stray label.
      final buttonLabel = link.isEmpty ? null : _buttonLabel;

      if (widget.existing == null) {
        await api.createBroadcast(
          title: title,
          body: body,
          priority: _priority,
          link: link.isEmpty ? null : link,
          buttonLabel: buttonLabel,
          imageUrl: imageUrl,
        );
      } else {
        await api.updateBroadcast(
          widget.existing!.id,
          title: title,
          body: body,
          priority: _priority,
          link: link.isEmpty ? null : link,
          buttonLabel: buttonLabel,
          imageUrl: imageUrl,
        );
      }
      ref.invalidate(adminBroadcastsProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _submitting = false;
        _uploadingImage = false;
        _error = 'Could not save — please try again.';
      });
    }
  }

  Widget _buildImagePicker() {
    final hasImage = _pickedImage != null || _existingImageUrl != null;

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: _uploadingImage ? null : _pickImage,
        icon: const Icon(Icons.image_outlined, size: 18),
        label: const Text('Add Image (optional)'),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 160,
            child: _pickedImage != null
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : Image.network(_existingImageUrl!, fit: BoxFit.cover),
          ),
        ),
        if (_uploadingImage)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _uploadingImage ? null : _removeImage,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'New Broadcast' : 'Edit Broadcast',
              style: TextStyle(
                fontFamily: AppText.brandFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.film,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              // Rebuild on edits so the CTA picker appears/disappears with the
              // link (the button only shows when a link is set).
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Link (optional)',
                hintText: 'https://…',
              ),
            ),
            // Button label (CTA) — only relevant when a link is present.
            if (_linkCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _buttonLabel,
                decoration: const InputDecoration(labelText: 'Button label'),
                items: _ctaLabels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(growable: false),
                onChanged: (v) =>
                    setState(() => _buttonLabel = v ?? _ctaLabels.first),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _priorities.map((p) {
                final selected = p == _priority;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() => _priority = p),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 16),
            _buildImagePicker(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                ),
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.onAccent,
                        ),
                      )
                    : Text(widget.existing == null ? 'Publish' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
