// lib/features/profile/presentation/profile_screen.dart
//
// Clicker Pro — Profile Screen (Claude Design · light "paper" theme)
//
// Visual: white surface section cards on the paper canvas, gradient avatar
// circle, role chip, mono section headers, gear/company pill rows.
//
// Wiring (this slice):
//   • currentUserProvider                 — single source of truth for the user
//   • gearListProvider(user.id)           — Drift-backed reactive gear stream
//   • rolePolicyProvider                  — capability gates (no role-string compares)
//   • userRepositoryProvider              — addGear / removeGear / updateProfile / getLifetimeStats
//   • teamInviteRepositoryProvider        — generate 6-digit invite code
//   • sessionControllerProvider           — change role
//   • languageControllerProvider          — i18n labels
//
// Animation tokens used:
//   • AnimatedSwitcher 200ms              — Save → spinner swap
//   • Curves.easeOutCubic 220ms           — section card mount
//   • slideFromRightRoute (from login)    — manager invite navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/format/number_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/presentation/role_change_dialog.dart';
import '../../settings/application/language_controller.dart';
import '../../team/application/team_providers.dart';
import '../application/profile_controllers.dart';
import '../domain/gear_item.dart';
import '../domain/user_model.dart';
import '../../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // UI-only flags. ALL persisted user fields live on the draft / user model.
  bool _isEditing = false;
  bool _isSaving = false;
  UserModel? _draft;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    // One-shot lifetime-stats refresh per Req 3.8. Fire-and-forget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Triggers /api/profile/lifetime-stats and updates the local cache.
      ref.read(userRepositoryProvider).getLifetimeStats();
      ref.read(userRepositoryProvider).refreshFromRemote();
    });
  }

  String get _lang => ref
      .read(languageControllerProvider)
      .maybeWhen(data: (c) => c, orElse: () => 'en');

  String t(String key) => AppStrings.get(key, _lang);

  @override
  Widget build(BuildContext context) {
    // Re-read on every rebuild so language toggles re-render labels.
    ref.watch(languageControllerProvider);

    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: userAsync.when(
              loading: () => const LensLoader(),
              error: (err, _) => ErrorState(
                message: 'Could not load your profile.',
                onRetry: () => ref.invalidate(currentUserProvider),
              ),
              data: (user) {
                if (user == null) {
                  // Defensive: any 401 has already cleared the session — bounce to Login.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  });
                  return const LensLoader();
                }
                return _buildBody(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar with overflow menu ────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final policy = ref.watch(rolePolicyProvider);
    return AppBar(
      backgroundColor: AppColors.appBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.film),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Profile',
        style: TextStyle(
          color: AppColors.film,
          fontFamily: AppText.brandFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: Icon(Icons.more_vert_rounded, color: AppColors.film),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.line(0.08)),
          ),
          onSelected: _onMenuSelected,
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            // Edit lives in the three-dot menu (Heaven's request) instead of a
            // standalone button. Hidden while an edit session is already open.
            if (!_isEditing)
              const PopupMenuItem<String>(
                value: 'edit_profile',
                child: _MenuRow(
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                ),
              ),
            if (policy.can(Capability.changeRole))
              const PopupMenuItem<String>(
                value: 'change_role',
                child: _MenuRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Change Role',
                ),
              ),
            if (policy.can(Capability.generateTeamInvite))
              const PopupMenuItem<String>(
                value: 'generate_invite',
                child: _MenuRow(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Generate Invite',
                ),
              ),
            const PopupMenuItem<String>(
              value: 'delete_account',
              child: _MenuRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Account',
                danger: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'edit_profile':
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null) {
          setState(() {
            _isEditing = true;
            _draft = user.copyWith();
          });
        }
        break;
      case 'change_role':
        await _handleChangeRole();
        break;
      case 'generate_invite':
        await _handleGenerateInvite();
        break;
      case 'delete_account':
        Navigator.of(context).pushNamed(RouteNames.deleteAccount);
        break;
    }
  }

  // ── Main body ──────────────────────────────────────────────────
  Widget _buildBody(UserModel user) {
    final policy = ref.watch(rolePolicyProvider);
    final view = _isEditing ? (_draft ?? user) : user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(view),
          const SizedBox(height: 30),

          _buildSectionTitle('Basic Information'),
          _buildProfileCard([
            _buildInfoField(
              label: 'Name',
              value: view.name,
              icon: Icons.person,
              onChanged: (val) => _updateDraft((d) => d.copyWith(name: val)),
            ),
            _buildInfoField(
              label: 'Phone',
              value: view.phone ?? '',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              onChanged: (val) => _updateDraft((d) => d.copyWith(phone: val)),
            ),
            _buildInfoField(
              label: t('whatsapp'),
              value: view.whatsapp ?? '',
              icon: Icons.message,
              keyboardType: TextInputType.phone,
              onChanged: (val) =>
                  _updateDraft((d) => d.copyWith(whatsapp: val)),
            ),
            _buildInfoField(
              label: 'Email',
              value: view.email,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              // Email is the login identity — the backend (correctly)
              // refuses to change it from the profile endpoint, so showing
              // it as editable was a lie. Read-only until a proper
              // change-email + re-verify flow exists.
              onChanged: null,
              isReadOnly: true,
            ),
            // Studio address is company information — a pure Freelancer has
            // no studio, so this field is hidden for them.
            if (policy.can(Capability.editStudioBranding))
              _buildInfoField(
                label: t('studio_address'),
                value: view.studioAddress ?? '',
                icon: Icons.location_on,
                onChanged: (val) =>
                    _updateDraft((d) => d.copyWith(studioAddress: val)),
              ),
            _buildInfoField(
              label: t('bio'),
              value: view.bio ?? '',
              icon: Icons.info,
              onChanged: (val) => _updateDraft((d) => d.copyWith(bio: val)),
            ),
            _buildInfoField(
              label: 'Role',
              value: view.role.displayLabel,
              icon: Icons.verified_user,
              onChanged: null,
              isReadOnly: true,
            ),
          ]),

          const SizedBox(height: 25),
          _buildSectionTitle('Financial Details'),
          _buildProfileCard([
            _buildInfoField(
              label: 'bKash Number',
              value: view.bkash ?? '',
              icon: Icons.payment,
              keyboardType: TextInputType.phone,
              onChanged: (val) => _updateDraft((d) => d.copyWith(bkash: val)),
            ),
            // Bank account lives behind one tile: collapsed = just the
            // bank name; tap = form sheet with the 4 payout fields.
            _buildBankTile(view),
          ]),

          // ── Gear inventory + companies (Freelancer / Both) ────
          if (policy.can(Capability.editGearInventory)) ...[
            const SizedBox(height: 25),
            _buildSectionTitle('Professional Skills'),
            _buildProfileCard([_buildSpecializationChips(view)]),
            const SizedBox(height: 25),
            _buildGearSection(user.id),
            const SizedBox(height: 25),
            _buildCompanySection(user),
          ],

          // ── Studio branding (Owner / Both) ────────────────────
          if (policy.can(Capability.editStudioBranding)) ...[
            const SizedBox(height: 25),
            _buildSectionTitle('Company & Business'),
            _buildProfileCard([
              // Company Name is captured once at registration — the duplicate
              // editable field here was removed per Heaven's request.
              _buildInfoField(
                label: t('vat_bin'),
                value: view.vatBin ?? '',
                icon: Icons.receipt_long,
                onChanged: (val) =>
                    _updateDraft((d) => d.copyWith(vatBin: val)),
              ),
              _buildInfoField(
                label: t('studio_logo'),
                value: (view.logoUrl != null && view.logoUrl!.isNotEmpty)
                    ? 'Uploaded'
                    : 'Not set',
                icon: Icons.image,
                onChanged: null,
                isUpload: true,
                onUpload: () => _pickAndUploadImage(
                  (url) => _updateDraft((d) => d.copyWith(logoUrl: url)),
                  successMessage: 'Logo uploaded — tap Save to keep it.',
                ),
              ),
              _buildInfoField(
                label: t('digital_signature'),
                value:
                    (view.signatureUrl != null && view.signatureUrl!.isNotEmpty)
                    ? 'Attached'
                    : 'Not set',
                icon: Icons.edit,
                onChanged: null,
                isUpload: true,
                onUpload: () => _pickAndUploadImage(
                  (url) => _updateDraft((d) => d.copyWith(signatureUrl: url)),
                  successMessage: 'Signature uploaded — tap Save to keep it.',
                ),
              ),
            ]),
          ],

          // ── Team Invite (Owner / Both) ───────────────────────────────
          if (policy.can(Capability.generateTeamInvite)) ...[
            const SizedBox(height: 25),
            _buildSectionTitle('Team Invite'),
            _buildInviteCard(),
          ],

          const SizedBox(height: 25),
          _buildLifetimeStats(user),

          const SizedBox(height: 32),
          _buildEditActions(user),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header (avatar + role chip) ───────────────────────────────
  Widget _buildHeader(UserModel user) {
    final hasPhoto = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final avatar = Container(
      width: 120,
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Solid accent only sits behind the gradient initials. With a real
        // photo it would peek out as an orange ring/frame, so leave it null.
        color: hasPhoto ? null : AppColors.accent,
        // Uploaded profile photo when present; gradient initials otherwise.
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(user.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
        // A spreading orange glow read as an unwanted frame around photos —
        // use a soft neutral drop shadow with no spread instead.
        boxShadow: [
          BoxShadow(
            color: hasPhoto
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.accent.withValues(alpha: 0.3),
            blurRadius: hasPhoto ? 16 : 20,
            spreadRadius: hasPhoto ? 0 : 5,
          ),
        ],
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                user.avatarInitials,
                style: TextStyle(
                  color: AppColors.onAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppText.brandFontFamily,
                  letterSpacing: 1.2,
                ),
              ),
            ),
    );

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Hero tag matches the dashboard avatar so the gradient circle
              // morphs into place when navigating Dashboard → Profile
              // (Task 20.9 / Req 5.1).
              Hero(tag: 'user-avatar-${user.id}', child: avatar),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: AppColors.accent,
                    radius: 18,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppColors.onAccent,
                      ),
                      onPressed: () => _pickAndUploadImage(
                        (url) => _updateDraft(
                          (d) => d.copyWith(avatarUrl: url),
                        ),
                        successMessage:
                            'Photo uploaded — tap Save to keep it.',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.studioLabel,
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontSize: 12,
              letterSpacing: 1.2,
              fontFamily: AppText.monoFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
            ),
            child: Text(
              user.role.displayLabel,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          Container(width: 26, height: 1.5, color: AppColors.orange),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.filmMuted,
              fontFamily: AppText.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: e.key != children.length - 1 ? 15 : 0,
            ),
            child: e.value,
          );
        }).toList(),
      ),
    );
  }

  // ── Specialization role chips (Photographer / Cinematographer / etc.) ──
  /// Bank details live in ONE backend column; the UI splits them into
  /// "bank | account | branch | holder". Legacy free-text values (no
  /// pipes) surface in the Bank Name field so nothing is lost.
  String _bankPart(String? raw, int index) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parts = raw.split('|').map((p) => p.trim()).toList();
    return index < parts.length ? parts[index] : '';
  }

  /// Collapsed bank tile: bank name only (or an "add" prompt). Tapping
  /// opens the 4-field form sheet so details stay hidden until asked.
  Widget _buildBankTile(UserModel view) {
    final bankName = _bankPart(view.bankDetails, 0);
    final hasBank = bankName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openBankSheet(view),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line(0.06)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 20,
                  color: hasBank ? AppColors.orange : AppColors.filmMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasBank ? bankName : 'Add Bank Account',
                        style: TextStyle(
                          color: hasBank ? AppColors.film : AppColors.filmDim,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasBank
                            ? 'Tap to view / edit details'
                            : 'Bank name, account number, branch, holder name',
                        style: TextStyle(
                          color: AppColors.filmDim.withValues(alpha: 0.7),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasBank)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.orange,
                    size: 18,
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.filmMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openBankSheet(UserModel view) async {
    final raw = (_isEditing ? _draft?.bankDetails : null) ?? view.bankDetails;
    final ctrls = List.generate(
      4,
      (i) => TextEditingController(text: _bankPart(raw, i)),
    );
    const labels = [
      'Bank Name',
      'Account Number',
      'Branch',
      'Account Holder Name',
    ];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bank Account Details',
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 4; i++) ...[
                TextField(
                  controller: ctrls[i],
                  keyboardType: i == 1 ? TextInputType.number : null,
                  style: TextStyle(color: AppColors.film, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: labels[i],
                    labelStyle: TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.line(0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.line(0.06),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.orange, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final parts = ctrls.map((c) => c.text.trim()).toList();
    for (final c in ctrls) {
      c.dispose();
    }
    if (saved != true) return;

    final joined = parts.every((p) => p.isEmpty) ? '' : parts.join(' | ');

    if (_isEditing) {
      // Editing session: stage in the draft; the profile Save commits.
      _updateDraft((d) => d.copyWith(bankDetails: joined));
      return;
    }

    // View mode: persist immediately so the tile works standalone.
    try {
      final updated = view.copyWith(bankDetails: joined);
      await ref.read(userRepositoryProvider).updateProfile(updated);
      if (!mounted) return;
      _showSnack('Bank details saved');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not save — please try again.');
    }
  }

  Widget _buildSpecializationChips(UserModel view) {
    const options = <({String value, String label, IconData icon})>[
      (
        value: 'photographer',
        label: 'Photographer',
        icon: Icons.photo_camera_outlined,
      ),
      (
        value: 'cinematographer',
        label: 'Cinematographer',
        icon: Icons.videocam_outlined,
      ),
      (
        value: 'photo_editor',
        label: 'Photo Editor',
        icon: Icons.auto_fix_high_outlined,
      ),
      (
        value: 'video_editor',
        label: 'Video Editor',
        icon: Icons.movie_filter_outlined,
      ),
      (value: 'manager', label: 'Manager', icon: Icons.shield_outlined),
    ];

    final raw = (view.specialization ?? '').trim();
    final selected = raw.isEmpty
        ? <String>{}
        : raw
              .split(',')
              .map((s) => s.trim().toLowerCase())
              .where((s) => s.isNotEmpty)
              .toSet();

    void toggle(String value) {
      if (!_isEditing) return;
      final next = {...selected};
      if (next.contains(value)) {
        next.remove(value);
      } else {
        next.add(value);
      }
      final sorted = next.toList()..sort();
      _updateDraft((d) => d.copyWith(specialization: sorted.join(',')));
    }

    // View mode shows ONLY the saved skills; the full option list is
    // for edit mode (showing unselected chips read as "skills you have").
    final visibleOptions = _isEditing
        ? options
        : options.where((o) => selected.contains(o.value)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, size: 16, color: AppColors.accent),
            SizedBox(width: 8),
            Text(
              'Specialization',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.filmDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleOptions.isEmpty)
          Text(
            'No skills saved — tap Edit.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.filmDim.withValues(alpha: 0.7),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleOptions.map((opt) {
            final isOn = selected.contains(opt.value);
            return GestureDetector(
              onTap: () => toggle(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOn
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : AppColors.line(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn
                        ? AppColors.accent.withValues(alpha: 0.55)
                        : AppColors.line(0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isOn ? AppColors.accent : AppColors.filmDim,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOn ? AppColors.film : AppColors.filmDim,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (!_isEditing && selected.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Tap Edit to add your specializations',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.filmMuted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }

  // ── Editable field row ────────────────────────────────────────
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required ValueChanged<String>? onChanged,
    bool isReadOnly = false,
    bool isUpload = false,
    VoidCallback? onUpload,
    TextInputType? keyboardType,
  }) {
    final canEdit = _isEditing && !isReadOnly && onChanged != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.filmDim, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.filmMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              if (canEdit)
                TextFormField(
                  initialValue: value,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  style: TextStyle(color: AppColors.film, fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                )
              else
                Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    // film (ink) — Colors.white vanished on the light card
                    // surface, which made saved values look "invisible".
                    color: value.isEmpty ? AppColors.filmMuted : AppColors.film,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (isUpload && _isEditing)
          IconButton(
            icon: Icon(
              Icons.upload_file,
              color: AppColors.accent,
              size: 20,
            ),
            onPressed: onUpload ?? () => _showSnack(t('coming_soon')),
          ),
      ],
    );
  }

  /// Picks an image from the gallery, uploads it to the backend, and hands
  /// the hosted URL to [apply] (which stores it on the profile draft).
  Future<void> _pickAndUploadImage(
    void Function(String url) apply, {
    required String successMessage,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    _showSnack('Uploading…');
    try {
      final url = await ref.read(userApiProvider).uploadImage(picked.path);
      if (!mounted) return;
      apply(url);
      _showSnack(successMessage);
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e');
    }
  }

  // ── Gear section (real Drift stream) ──────────────────────────
  Widget _buildGearSection(String userId) {
    final gearAsync = ref.watch(gearListProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('prof_gear'),
              style: TextStyle(
                color: AppColors.film,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isEditing)
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.accent),
                onPressed: () => _showAddGearDialog(userId),
              ),
          ],
        ),
        const SizedBox(height: 10),
        gearAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LensLoader(size: 22),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load gear',
              style: TextStyle(
                color: AppColors.red.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ),
          data: (gear) {
            if (gear.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No gear yet. Tap + to add.',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Column(children: [for (final g in gear) _buildGearRow(g)]);
          },
        ),
      ],
    );
  }

  Widget _buildGearRow(GearItem gear) {
    final subtitle = (gear.brand != null && gear.brand!.trim().isNotEmpty)
        ? '${gear.name} · ${gear.brand}'
        : gear.name;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.camera, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(subtitle, style: TextStyle(color: AppColors.film)),
          ),
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red.withValues(alpha: 0.85),
                size: 20,
              ),
              onPressed: () => _removeGear(gear),
            ),
        ],
      ),
    );
  }

  Future<void> _removeGear(GearItem gear) async {
    try {
      await ref.read(userRepositoryProvider).removeGear(gear.id);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not remove gear');
    }
  }

  // ── Companies section ─────────────────────────────────────────
  Widget _buildCompanySection(UserModel user) {
    // Companies aren't yet on the canonical UserModel — surface empty list as
    // the legacy contract did. Real companies arrive in Phase 2.
    final companies = const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('my_companies'),
          style: TextStyle(
            color: AppColors.film,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (companies.isEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _openManagerInvite,
              icon: Icon(Icons.group_add, color: AppColors.accent),
              label: Text(
                t('join_team'),
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          )
        else
          for (final company in companies)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line(0.06)),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: AppColors.indigo, size: 18),
                  const SizedBox(width: 10),
                  Text(company, style: TextStyle(color: AppColors.film)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
      ],
    );
  }

  /// Join a team. Per Heaven's requirement, joining needs ONLY the owner's
  /// 6-digit passcode — no name/email/password (the user is already logged in,
  /// so their identity is known). This opens a minimal passcode sheet that
  /// calls the team/join endpoint.
  void _openManagerInvite() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _JoinByPasscodeSheet(),
    );
  }

  // ── Team invite card (visible for Owner / Both) ───────────────
  Widget _buildInviteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Manager invite code',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.film,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Generate a 6-digit code to invite a manager into your company.\nCode expires in 24 hours.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.filmDim,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleGenerateInvite,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Generate Invite Code',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.film,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lifetime stats card ───────────────────────────────────────
  Widget _buildLifetimeStats(UserModel user) {
    final loading = user.statsRefreshedAt == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(t('lifetime_stats')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line(0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.event_available_rounded,
                  label: 'Events',
                  value: loading ? null : user.totalEvents.toString(),
                ),
              ),
              _vDivider(),
              Expanded(
                child: _statTile(
                  icon: Icons.payments_rounded,
                  label: 'Revenue',
                  value: loading
                      ? null
                      : formatCurrencyBdt(
                          user.totalRevenueMinor / 100,
                          lang: _lang,
                        ),
                ),
              ),
              _vDivider(),
              Expanded(
                child: _statTile(
                  icon: Icons.people_alt_rounded,
                  label: 'Clients',
                  value: loading ? null : user.totalClients.toString(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: value == null
              ? const Padding(
                  key: ValueKey('loading'),
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: LensLoader(size: 16),
                )
              : Text(
                  value,
                  key: ValueKey(value),
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.filmMuted,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 32,
    color: AppColors.line(0.06),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // ── Edit / Save / Cancel buttons ──────────────────────────────
  Widget _buildEditActions(UserModel user) {
    // Edit is now started from the three-dot menu, so outside an edit session
    // there is no bottom action button — only the Save/Cancel row shows while
    // editing.
    if (!_isEditing) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.filmDim,
                side: BorderSide(color: AppColors.line(0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.orange,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isSaving ? null : _onSave,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isSaving
                        ? SizedBox(
                            key: ValueKey('saving'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.film,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            t('save_changes'),
                            key: const ValueKey('save'),
                            style: TextStyle(
                              color: AppColors.film,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateDraft(UserModel Function(UserModel d) mutator) {
    final base = _draft;
    if (base == null) return;
    setState(() => _draft = mutator(base));
  }

  void _onCancel() {
    if (_isSaving) return;
    setState(() {
      _isEditing = false;
      _draft = null;
    });
  }

  Future<void> _onSave() async {
    final draft = _draft;
    if (draft == null) return;

    final err = _validateDraft(draft);
    if (err != null) {
      _showSnack(err);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(draft);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _draft = null;
      });
      _showSnack('Profile updated');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Could not save profile');
    }
  }

  String? _validateDraft(UserModel draft) {
    final name = draft.name.trim();
    if (name.isEmpty || name.length > 80) {
      return 'Name must be 1–80 characters';
    }
    if (!_emailRegex.hasMatch(draft.email.trim())) {
      return 'Enter a valid email';
    }
    final phone = draft.phone?.trim() ?? '';
    if (phone.isNotEmpty && !RegExp(r'^[0-9+\- ]+$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ── Add gear dialog ───────────────────────────────────────────
  Future<void> _showAddGearDialog(String userId) async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.line(0.08)),
          ),
          title: Text(
            t('add_gear'),
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppColors.film),
            decoration: InputDecoration(
              hintText: 'e.g. Canon EOS R5',
              hintStyle: TextStyle(color: AppColors.filmMuted),
              errorText: errorText,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.line(0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.filmDim),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty || name.length > 80) {
                  setLocal(() => errorText = 'Must be 1–80 characters');
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text('Save', style: TextStyle(color: AppColors.film)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final name = controller.text.trim();
      final item = GearItem(
        id: 'gear_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        name: name,
      );
      try {
        await ref.read(userRepositoryProvider).addGear(item);
      } catch (_) {
        if (!mounted) return;
        _showSnack('Could not add gear');
      }
    }
    // Dialog has closed and the controller's text has been consumed above;
    // dispose it to avoid a leak.
    controller.dispose();
  }

  // ── Change role flow ──────────────────────────────────────────
  Future<void> _handleChangeRole() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final picked = await RoleChangeDialog.show(context, user.role);
    if (picked == null) return; // Cancel — no network call (Req 3.10).
    try {
      await ref.read(sessionControllerProvider.notifier).changeRole(picked);
      if (!mounted) return;
      final state = ref.read(sessionControllerProvider);
      if (state.hasError) {
        _showSnack('Could not change role');
        return;
      }
      // Pull the authoritative profile back + refresh the role-driven
      // providers so the whole UI (capabilities, tabs, finance) reflects
      // the new role immediately — not just after a restart.
      await ref.read(userRepositoryProvider).refreshFromRemote();
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      _showSnack('Role updated to ${picked.displayLabel}');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not change role');
    }
  }

  // ── Generate invite flow ──────────────────────────────────────
  Future<void> _handleGenerateInvite() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: LensLoader()),
    );
    try {
      final invite = await ref
          .read(teamInviteRepositoryProvider)
          .generateInvite();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showInviteCodeDialog(invite.code, invite.expiresAt);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack('Could not generate invite');
    }
  }

  Future<void> _showInviteCodeDialog(String code, DateTime expiresAt) async {
    final hours = expiresAt.difference(DateTime.now()).inHours;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Text(
          'Manager invite',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with the manager you want to invite.',
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: AppText.monoFontFamily,
                  color: AppColors.gold,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hours > 0 ? 'Expires in $hours hours' : 'Expires soon',
              style: TextStyle(
                color: AppColors.filmMuted,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.copy_rounded,
              color: AppColors.gold,
              size: 18,
            ),
            label: Text('Copy', style: TextStyle(color: AppColors.gold)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!mounted) return;
              _showSnack('Invite code copied');
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: AppColors.film, fontSize: 13),
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.line(0.08)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ── Popup-menu row (icon + label, optional danger tint) ────────
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.film;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13.5)),
      ],
    );
  }
}

/// Minimal "join a team" sheet: the user (already logged in) enters ONLY the
/// owner's 6-digit passcode. No name/email/password — their account already
/// exists. Calls the team/join endpoint via [teamControllerProvider].
class _JoinByPasscodeSheet extends ConsumerStatefulWidget {
  const _JoinByPasscodeSheet();

  @override
  ConsumerState<_JoinByPasscodeSheet> createState() =>
      _JoinByPasscodeSheetState();
}

class _JoinByPasscodeSheetState extends ConsumerState<_JoinByPasscodeSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit passcode.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(teamControllerProvider.notifier).joinWithCode(code);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined the team ✓')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Passcode is wrong or expired.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        22,
        24,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.filmMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Join a team',
            style: TextStyle(
              color: AppColors.film,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit passcode your studio owner shared with you.',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.film,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(
                color: AppColors.filmMuted.withValues(alpha: 0.5),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.line(0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.line(0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.orange.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.onAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.onAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Join Team',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
