// lib/features/settings/presentation/settings_screen.dart
//
// Clicker Pro — Settings Screen (Dark Luxury Lens)
//
// Visual: PRESERVED from the legacy screen — Container(... AppColors.glass,
// border ...), uppercase section header in orange, group cards, list/toggle
// rows.
//
// Wiring (this slice):
//   • languageControllerProvider          — read / setLanguage
//   • rolePolicyProvider                  — capability gates
//   • currentUserProvider                 — userId for per-user prefs
//   • notificationPrefsProvider(userId)   — Drift-backed reactive stream
//   • preferencesRepositoryProvider       — distribution / vat / bn-numerals
//   • sessionControllerProvider           — logout
//
// All toggle persistence runs through the repository. UI does NOT define
// defaults — those live in `NotificationPrefs.defaults`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme_mode.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/language_controller.dart';
import '../domain/preferences_repository.dart';

/// Stream notification preferences from Drift, keyed by user id.
final notificationPrefsProvider =
    StreamProvider.family<NotificationPrefs, String>((ref, userId) {
      return ref
          .watch(preferencesRepositoryProvider)
          .watchNotificationPrefs(userId);
    });

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Cached one-shot values for prefs that don't have a stream yet.
  bool? _distributionEnabled;
  bool? _vatEnabled;
  bool? _bengaliNumerals;
  String? _initializedForUserId;

  @override
  Widget build(BuildContext context) {
    final lang = ref
        .watch(languageControllerProvider)
        .maybeWhen(data: (c) => c, orElse: () => 'en');
    final policy = ref.watch(rolePolicyProvider);
    final user = ref.watch(currentUserProvider).value;

    if (user != null && _initializedForUserId != user.id) {
      _initializedForUserId = user.id;
      _distributionEnabled = null;
      _vatEnabled = null;
      _bengaliNumerals = null;
      _loadOneShotPrefs(user.id);
    }

    String t(String key) => AppStrings.get(key, lang);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Preferences · System'),
                  _buildSettingsGroup([
                    _buildThemeToggle(lang, t),
                    _buildLanguageRow(lang, t),
                    _buildListItem(
                      label: t('pref_customize_dashboard'),
                      icon: Icons.tune_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.dashboardCustomize,
                      ),
                    ),
                    if (user != null) _buildNotificationsGroup(user.id, t),
                  ]),

                  if (policy.can(Capability.toggleDistribution) ||
                      policy.can(Capability.toggleVat)) ...[
                    const SizedBox(height: 30),
                    _sectionHeader('Business'),
                    _buildSettingsGroup([
                      if (policy.can(Capability.toggleDistribution))
                        _buildBoolRow(
                          label: t('pref_dist'),
                          icon: Icons.share_rounded,
                          value: _distributionEnabled,
                          onChanged: user == null
                              ? null
                              : (v) => _setDistribution(user.id, v),
                        ),
                      if (policy.can(Capability.toggleVat))
                        _buildBoolRow(
                          label: t('biz_vat'),
                          icon: Icons.receipt_long_rounded,
                          value: _vatEnabled,
                          onChanged: user == null
                              ? null
                              : (v) => _setVat(user.id, v),
                        ),
                      _buildListItem(
                        label: t('biz_studio'),
                        icon: Icons.business,
                        // Studio/company details (name, VAT BIN, logo, address,
                        // signature) are edited in the profile screen's
                        // "Company & Business" section — route there instead of
                        // duplicating the form.
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.profile),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 30),
                  _sectionHeader('App'),
                  _buildSettingsGroup([
                    if (user != null)
                      _buildBoolRow(
                        label: 'Bengali Numerals',
                        icon: Icons.format_list_numbered_rounded,
                        value: _bengaliNumerals,
                        onChanged: (v) => _setBengaliNumerals(user.id, v),
                      ),
                    _buildListItem(
                      label: t('app_about'),
                      icon: Icons.info_outline,
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildListItem(
                      label: t('app_help'),
                      icon: Icons.help_outline,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.help),
                    ),
                    _buildListItem(
                      label: 'Security',
                      icon: Icons.security_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.securitySettings,
                      ),
                    ),
                    _buildListItem(
                      label: t('app_privacy'),
                      icon: Icons.privacy_tip_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.privacy),
                    ),
                    _buildListItem(
                      label: t('app_terms'),
                      icon: Icons.description_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.terms),
                    ),
                    _buildListItem(
                      label: 'Data Export',
                      icon: Icons.cloud_download_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.dataExport),
                    ),
                  ]),

                  const SizedBox(height: 30),
                  _sectionHeader('Advanced'),
                  _buildSettingsGroup([
                    _buildListItem(
                      label: 'Calendar Sync',
                      icon: Icons.calendar_today_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.calendarSyncSettings,
                      ),
                    ),
                    _buildListItem(
                      label: 'Home Widget',
                      icon: Icons.widgets_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.widgetSettings,
                      ),
                    ),
                    _buildListItem(
                      label: 'Backup & Restore',
                      icon: Icons.backup_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.backup),
                    ),
                    _buildListItem(
                      label: 'Audit Log',
                      icon: Icons.history_edu_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.auditLog),
                    ),
                    _buildListItem(
                      label: 'Crash Reports',
                      icon: Icons.bug_report_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.crashSettings,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  _sectionHeader('Account'),
                  _buildSettingsGroup([
                    _buildListItem(
                      label: t('menu_logout'),
                      icon: Icons.logout_rounded,
                      danger: true,
                      onTap: _handleLogout,
                    ),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Async one-shot prefs (distribution / vat / bn numerals) ───
  Future<void> _loadOneShotPrefs(String userId) async {
    final repo = ref.read(preferencesRepositoryProvider);
    try {
      final dist = await repo.getDistributionEnabled(userId);
      final vat = await repo.getVatEnabled(userId);
      final bn = await repo.getBengaliNumerals(userId);
      if (!mounted) return;
      setState(() {
        _distributionEnabled = dist;
        _vatEnabled = vat;
        _bengaliNumerals = bn;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _distributionEnabled = false;
        _vatEnabled = false;
        _bengaliNumerals = false;
      });
    }
  }

  Future<void> _setDistribution(String userId, bool value) async {
    final prev = _distributionEnabled;
    setState(() => _distributionEnabled = value);
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setDistributionEnabled(userId, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _distributionEnabled = prev);
      _showSnack('Could not save preference');
    }
  }

  Future<void> _setVat(String userId, bool value) async {
    final prev = _vatEnabled;
    setState(() => _vatEnabled = value);
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setVatEnabled(userId, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _vatEnabled = prev);
      _showSnack('Could not save preference');
    }
  }

  Future<void> _setBengaliNumerals(String userId, bool value) async {
    final prev = _bengaliNumerals;
    setState(() => _bengaliNumerals = value);
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setBengaliNumerals(userId, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bengaliNumerals = prev);
      _showSnack('Could not save preference');
    }
  }

  // ── Notification preferences (Drift stream) ───────────────────
  Widget _buildNotificationsGroup(String userId, String Function(String) t) {
    final prefsAsync = ref.watch(notificationPrefsProvider(userId));
    return prefsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          height: 22,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => _buildBoolRow(
        label: t('pref_notif'),
        icon: Icons.notifications_outlined,
        value: false,
        onChanged: null,
      ),
      data: (prefs) => Column(
        children: [
          _buildBoolRow(
            label: t('notif_event_reminders'),
            icon: Icons.alarm_rounded,
            value: prefs.eventReminders,
            onChanged: (v) =>
                _saveNotifPrefs(userId, prefs.copyWith(eventReminders: v)),
          ),
          _buildBoolRow(
            label: t('notif_payment_due'),
            icon: Icons.payments_outlined,
            value: prefs.paymentDue,
            onChanged: (v) =>
                _saveNotifPrefs(userId, prefs.copyWith(paymentDue: v)),
          ),
          _buildBoolRow(
            label: t('notif_team_messages'),
            icon: Icons.chat_bubble_outline_rounded,
            value: prefs.teamMessages,
            onChanged: (v) =>
                _saveNotifPrefs(userId, prefs.copyWith(teamMessages: v)),
          ),
          _buildBoolRow(
            label: t('notif_announcements'),
            icon: Icons.campaign_outlined,
            value: prefs.announcements,
            onChanged: (v) =>
                _saveNotifPrefs(userId, prefs.copyWith(announcements: v)),
          ),
          _buildBoolRow(
            label: t('notif_marketing'),
            icon: Icons.local_offer_outlined,
            value: prefs.marketing,
            onChanged: (v) =>
                _saveNotifPrefs(userId, prefs.copyWith(marketing: v)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNotifPrefs(String userId, NotificationPrefs prefs) async {
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .setNotificationPrefs(userId, prefs);
    } catch (_) {
      if (!mounted) return;
      // The stream emit will revert the UI; just surface the error.
      _showSnack('Could not save preference');
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Text(
          'Sign out of Clicker Pro?',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 13,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.film),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(sessionControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Visual primitives ─────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.filmDim.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.line(0.05),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // ListTile children paint their ink/splash on the nearest Material.
      // Without this transparent Material they'd paint on the colored
      // Container above and stay invisible (Flutter asserts about it).
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }

  /// Per-row accent colour — modern settings screens colour-code their
  /// icons instead of a flat monochrome list.
  Color _settingsTint(IconData icon) {
    if (icon == Icons.notifications_outlined ||
        icon == Icons.notifications_active_outlined) {
      return AppColors.red;
    }
    if (icon == Icons.lock_outline ||
        icon == Icons.security ||
        icon == Icons.shield_outlined) {
      return AppColors.indigo;
    }
    if (icon == Icons.backup_outlined ||
        icon == Icons.download_outlined ||
        icon == Icons.file_download_outlined) {
      return AppColors.green;
    }
    if (icon == Icons.description_outlined ||
        icon == Icons.privacy_tip_outlined ||
        icon == Icons.info_outline) {
      return AppColors.gold;
    }
    return AppColors.orange;
  }

  Widget _buildLanguageRow(String currentLang, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppColors.filmDim, size: 20),
              const SizedBox(width: 12),
              Text(
                t('pref_lang'),
                style: TextStyle(color: AppColors.film, fontSize: 15),
              ),
            ],
          ),
          SizedBox(
            width: 140,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 6),
                ),
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'bn', label: Text('BN')),
              ],
              selected: {currentLang},
              onSelectionChanged: (val) async {
                final newLang = val.first;
                await ref
                    .read(languageControllerProvider.notifier)
                    .setLanguage(newLang);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(String lang, String Function(String) t) {
    final asyncMode = ref.watch(themeModeControllerProvider);
    final currentMode = asyncMode.maybeWhen(
      data: (m) => m,
      orElse: () => AppThemeMode.dark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: AppColors.filmDim,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: TextStyle(color: AppColors.film, fontSize: 15),
              ),
            ],
          ),
          SizedBox(
            width: 200,
            child: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 6),
                ),
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text('System'),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (val) async {
                await ref
                    .read(themeModeControllerProvider.notifier)
                    .setThemeMode(val.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolRow({
    required String label,
    required IconData icon,
    required bool? value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.filmDim, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: AppColors.film, fontSize: 15),
              ),
            ],
          ),
          if (value == null)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2,
              ),
            )
          else
            Switch(
              value: value,
              activeThumbColor: AppColors.accent,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final tint = danger ? AppColors.red : _settingsTint(icon);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: tint, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.red : AppColors.film,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.filmMuted, size: 20),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Row(
          children: [
            Image.asset('assets/brand/logo_flower.png', width: 28, height: 28),
            const SizedBox(width: 10),
            Text(
              'CLICKER PRO',
              style: TextStyle(color: AppColors.film, fontFamily: 'Poppins'),
            ),
          ],
        ),
        content: Text(
          'Company management for photographers in Bangladesh.\n'
          'Version 3.8 · by waLidu Tech',
          style: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.gold)),
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
          backgroundColor: AppColors.voidElevated,
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
