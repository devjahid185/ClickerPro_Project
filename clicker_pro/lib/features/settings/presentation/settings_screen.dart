// lib/features/settings/presentation/settings_screen.dart
//
// Clicker Pro — Settings Screen (Claude Design · light "paper" theme)
//
// Visual: white surface group cards on the paper canvas, mono uppercase
// section headers with the signature orange rule, colour-coded list/toggle
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

import '../../../core/format/currency.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../shared/widgets/clicker_logo.dart';
import '../../../shared/widgets/pill_toggle.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_theme_mode.dart';
import '../../../theme/reduce_motion.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/application/profile_controllers.dart';
import '../application/currency_controller.dart';
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
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
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
                  // Profile hero (.dc.html): avatar + name + phone + role badge.
                  if (user != null) ...[
                    _buildProfileHero(user),
                    const SizedBox(height: 24),
                  ],
                  _sectionHeader('Preferences · System'),
                  _buildSettingsGroup([
                    _buildThemeToggle(lang, t),
                    // Language toggle removed — the app ships English only for
                    // now, so a Bengali switch that does nothing was misleading.
                    _buildListItem(
                      label: t('pref_customize_dashboard'),
                      icon: Icons.tune_outlined,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.dashboardCustomize,
                      ),
                    ),
                    if (user != null)
                      _buildNotificationsGroup(
                        user.id,
                        t,
                        // A pure Freelancer manages no team and runs no
                        // marketing, so those notification toggles are hidden.
                        showTeamAndMarketing: policy.can(
                          Capability.viewTeamSection,
                        ),
                      ),
                  ]),

                  if (policy.can(Capability.toggleDistribution) ||
                      policy.can(Capability.toggleVat) ||
                      policy.can(Capability.editStudioBranding)) ...[
                    const SizedBox(height: 30),
                    _sectionHeader('Business'),
                    _buildSettingsGroup([
                      // Studio currency — drives every money symbol across the
                      // app. Owner-set so a studio in any country sees its own.
                      if (policy.can(Capability.editStudioBranding))
                        _buildListItem(
                          label:
                              'Currency · '
                              '${ref.watch(activeCurrencyProvider).code}',
                          icon: Icons.payments_outlined,
                          onTap: _showCurrencyPicker,
                        ),
                      // Tax / VAT setup — rate + label used on invoices. Each
                      // country's system differs, so both are configurable.
                      if (policy.can(Capability.editStudioBranding))
                        _buildListItem(
                          label: _vatSummaryLabel(),
                          icon: Icons.receipt_long_rounded,
                          onTap: _showVatSetup,
                        ),
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
                      // Studio/company details (name, VAT BIN, logo, address,
                      // signature) only exist for studio owners. A pure
                      // Freelancer runs no studio, so the "Company" entry is
                      // hidden for them — gated on editStudioBranding (owner/both).
                      if (policy.can(Capability.editStudioBranding))
                        _buildListItem(
                          label: t('biz_studio'),
                          icon: Icons.business,
                          onTap: () =>
                              Navigator.pushNamed(context, RouteNames.profile),
                        ),
                    ]),
                  ],

                  const SizedBox(height: 30),
                  _sectionHeader('App'),
                  _buildSettingsGroup([
                    // Reduce motion — drops entrance/press animations for a
                    // smoother feel on low-RAM phones.
                    _buildBoolRow(
                      label: 'Reduce motion',
                      icon: Icons.animation_rounded,
                      value: ref
                          .watch(reduceMotionControllerProvider)
                          .maybeWhen(data: (v) => v, orElse: () => null),
                      onChanged: (v) => ref
                          .read(reduceMotionControllerProvider.notifier)
                          .setReduceMotion(v),
                    ),
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

  /// Bottom-sheet currency picker. Writes the choice through the currency
  /// controller, which updates ActiveCurrency so every money render switches.
  Future<void> _showCurrencyPicker() async {
    final current = ref.read(activeCurrencyProvider);
    final picked = await showModalBottomSheet<Currency>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'CURRENCY',
                      style: TextStyle(
                        fontFamily: AppText.monoFontFamily,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kCurrencies.length,
                  itemBuilder: (_, i) {
                    final c = kCurrencies[i];
                    final selected = c.code == current.code;
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 34,
                        child: Text(
                          c.symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.film,
                          ),
                        ),
                      ),
                      title: Text(
                        '${c.code} · ${c.name}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.film,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_rounded, color: AppColors.orange)
                          : null,
                      onTap: () => Navigator.of(sheetCtx).pop(c),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && picked.code != current.code) {
      await ref.read(currencyControllerProvider.notifier).setCurrency(picked);
      if (mounted) _showSnack('Currency set to ${picked.code}');
    }
  }

  /// Summary shown on the Business "Tax / VAT" row, e.g. "Tax · VAT 15%" or
  /// "Tax · Off".
  String _vatSummaryLabel() {
    final cfg = ref.watch(currencyControllerProvider).valueOrNull;
    if (cfg == null || !cfg.vatEnabled) return 'Tax · Off';
    final rate = cfg.vatRatePct;
    final rateStr = rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toString();
    return 'Tax · ${cfg.vatLabel} $rateStr%';
  }

  /// Tax/VAT setup sheet: enable, rate %, and label (VAT / GST / Tax / SST).
  Future<void> _showVatSetup() async {
    final cfg = ref.read(currencyControllerProvider).valueOrNull ??
        const CurrencyConfig(currency: kDefaultCurrency);
    bool enabled = cfg.vatEnabled;
    final rateCtl = TextEditingController(
      text: cfg.vatRatePct == 0
          ? ''
          : (cfg.vatRatePct % 1 == 0
                ? cfg.vatRatePct.toStringAsFixed(0)
                : cfg.vatRatePct.toString()),
    );
    final labelCtl = TextEditingController(text: cfg.vatLabel);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAX / VAT',
                  style: TextStyle(
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.orange,
                  title: Text(
                    'Add a tax line to invoices',
                    style: TextStyle(color: AppColors.film, fontSize: 14),
                  ),
                  value: enabled,
                  onChanged: (v) => setSheet(() => enabled = v),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: labelCtl,
                  enabled: enabled,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Tax name (VAT / GST / Tax / SST)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtl,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rate %',
                    hintText: 'e.g. 15',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(true),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true) {
      final rate = double.tryParse(rateCtl.text.trim()) ?? 0;
      final label = labelCtl.text.trim().isEmpty
          ? 'VAT'
          : labelCtl.text.trim();
      await ref.read(currencyControllerProvider.notifier).setVat(
            enabled: enabled,
            ratePct: rate,
            label: label,
          );
      if (mounted) _showSnack('Tax settings saved');
    }
    rateCtl.dispose();
    labelCtl.dispose();
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
  Widget _buildNotificationsGroup(
    String userId,
    String Function(String) t, {
    required bool showTeamAndMarketing,
  }) {
    final prefsAsync = ref.watch(notificationPrefsProvider(userId));
    return prefsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          if (showTeamAndMarketing)
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
          if (showTeamAndMarketing)
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Text(
          'Sign out of Clicker Pro?',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
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
      padding: const EdgeInsets.only(bottom: 12, top: 6, left: 4),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 1.5,
            color: AppColors.orange,
          ),
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

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
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

  Widget _buildThemeToggle(String lang, String Function(String) t) {
    final asyncMode = ref.watch(themeModeControllerProvider);
    final currentMode = asyncMode.maybeWhen(
      data: (m) => m,
      orElse: () => AppThemeMode.clickerPro,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.filmDim, size: 20),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: TextStyle(color: AppColors.film, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _themeCard(
                  title: 'ClickerPro',
                  subtitle: 'Editorial · default',
                  selected: currentMode == AppThemeMode.clickerPro,
                  swatch: const [
                    Color(0xFFFBFAF7),
                    Color(0xFFE2620E),
                    Color(0xFF1A1A18),
                  ],
                  onTap: () => ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(AppThemeMode.clickerPro),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _themeCard(
                  title: 'Noir',
                  subtitle: 'Lime · dark',
                  selected: currentMode == AppThemeMode.noirDark,
                  swatch: const [
                    Color(0xFF060708),
                    Color(0xFFC8F252),
                    Color(0xFFEDF1EA),
                  ],
                  onTap: () => ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(AppThemeMode.noirDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A tappable theme preview card: name + a 3-swatch colour strip, with an
  /// orange ring when selected.
  Widget _themeCard({
    required String title,
    required String subtitle,
    required bool selected,
    required List<Color> swatch,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.line(0.06),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final c in swatch)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.hairline),
                    ),
                  ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, color: AppColors.orange, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.film,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.filmDim.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile hero card (.dc.html): circular avatar (initials on the accent
  /// fill), name + phone, and a role badge chip on the right.
  Widget _buildProfileHero(dynamic user) {
    final initials = user.avatarInitials as String? ?? '..';
    final name = user.name as String? ?? 'User';
    final phone = (user.phone as String?)?.trim();
    final roleLabel = (user.studioLabel as String? ?? '').toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.profile),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.onAccent,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (roleLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
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
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2,
              ),
            )
          else
            PillToggle(value: value, onChanged: onChanged),
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
          fontWeight: FontWeight.w600,
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.line(0.08)),
        ),
        title: Row(
          children: [
            const ClickerLogo(size: 28),
            const SizedBox(width: 10),
            Text(
              'CLICKER PRO',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: AppText.bodyFontFamily,
              ),
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
            child: Text('Close', style: TextStyle(color: AppColors.gold)),
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
