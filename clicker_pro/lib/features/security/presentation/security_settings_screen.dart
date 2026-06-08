// lib/features/security/presentation/security_settings_screen.dart
//
// Clicker Pro — Security Settings screen (PROD-04)
//
// Sections: Change password, 2FA placeholder, Active sessions placeholder,
// Last login info, Privacy settings.
// Follows SettingsScreen visual pattern (glass cards, section headers).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  static const _key2FA = 'security_2fa_enabled';
  static const _keyOnlineStatus = 'security_online_status';
  static const _keyReadReceipts = 'security_read_receipts';
  static const _keyProfileVisible = 'security_profile_visible';
  static const _keyLastLogin = 'security_last_login_ts';

  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _twoFactorEnabled = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _onlineStatus = true;
  bool _readReceipts = true;
  bool _profileVisible = true;
  String _lastLoginStr = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Record this session's login time if not set
    if (!prefs.containsKey(_keyLastLogin)) {
      await prefs.setString(
        _keyLastLogin,
        DateTime.now().toIso8601String(),
      );
    }
    final ts = prefs.getString(_keyLastLogin);
    String loginStr = 'Unknown';
    if (ts != null) {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dtDay = DateTime(dt.year, dt.month, dt.day);
        final mm = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour < 12 ? 'AM' : 'PM';
        final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        if (dtDay == today) {
          loginStr = 'Today, $hour12:$mm $period';
        } else {
          loginStr =
              '${dt.day}/${dt.month}/${dt.year} $hour12:$mm $period';
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _twoFactorEnabled = prefs.getBool(_key2FA) ?? false;
      _onlineStatus = prefs.getBool(_keyOnlineStatus) ?? true;
      _readReceipts = prefs.getBool(_keyReadReceipts) ?? true;
      _profileVisible = prefs.getBool(_keyProfileVisible) ?? true;
      _lastLoginStr = loginStr;
    });

    // Sync real 2FA status from the backend.
    try {
      final r = await ref.read(apiClientProvider).get('/api/security/2fa/status')
          as Map<String, dynamic>;
      final enabled = (r['data']?['enabled'] as bool?) ?? false;
      if (mounted) {
        setState(() => _twoFactorEnabled = enabled);
        await prefs.setBool(_key2FA, enabled);
      }
    } catch (_) {/* offline — keep cached value */}
  }

  /// Toggle 2FA: enabling runs setup→verify (code dialog); disabling calls API.
  Future<void> _handleToggle2FA(bool enable) async {
    final client = ref.read(apiClientProvider);
    if (!enable) {
      try {
        await client.post('/api/security/2fa/disable');
        setState(() => _twoFactorEnabled = false);
        _setPref(_key2FA, false);
        _showSnack('Two-factor authentication disabled');
      } catch (_) {
        _showSnack('Could not disable 2FA');
      }
      return;
    }

    // Enable: fetch a secret/QR, then ask for the 6-digit code to verify.
    try {
      final setup = await client.post('/api/security/2fa/setup')
          as Map<String, dynamic>;
      final secret = setup['data']?['secret']?.toString() ?? '';
      if (!mounted) return;
      final code = await _ask2FACode(secret);
      if (code == null || code.isEmpty) return;
      await client.post('/api/security/2fa/verify', body: {'token': code});
      setState(() => _twoFactorEnabled = true);
      _setPref(_key2FA, true);
      _showSnack('Two-factor authentication enabled');
    } catch (_) {
      _showSnack('Invalid code — 2FA not enabled');
    }
  }

  Future<String?> _ask2FACode(String secret) async {
    final codeCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: const Text('Enable 2FA',
            style: TextStyle(color: AppColors.film, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add this secret to your authenticator app (Google Authenticator, Authy), then enter the 6-digit code.',
              style: TextStyle(color: AppColors.filmMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SelectableText(
              secret,
              style: const TextStyle(
                color: AppColors.gold,
                fontFamily: 'monospace',
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: AppColors.film, fontSize: 18, letterSpacing: 4),
              decoration: const InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: AppColors.filmMuted),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.filmMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(codeCtrl.text.trim()),
            child: const Text('Verify', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Security',
          style: TextStyle(
            fontFamily: AppText.brand.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.film,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Change Password'),
            _buildSettingsGroup([
              _buildPasswordField(
                label: 'Current Password',
                controller: _currentPwCtrl,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              _buildPasswordField(
                label: 'New Password',
                controller: _newPwCtrl,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              _buildPasswordField(
                label: 'Confirm Password',
                controller: _confirmPwCtrl,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 8),
              _buildChangePasswordButton(),
            ]),

            const SizedBox(height: 30),
            _sectionHeader('Two-Factor Authentication'),
            _buildSettingsGroup([
              _buildToggleRow(
                label: 'Enable 2FA',
                icon: Icons.shield_outlined,
                value: _twoFactorEnabled,
                onChanged: (v) => _handleToggle2FA(v),
                subtitle: _twoFactorEnabled
                    ? 'Authenticator app active'
                    : 'Add an extra layer of security',
              ),
            ]),

            const SizedBox(height: 30),
            _sectionHeader('Active Sessions'),
            _buildSettingsGroup([
              // Auth is stateless long-lived JWT with no server-side session
              // table, so we can only show *this* device honestly. Multi-device
              // session listing/revoke needs backend session tracking (not yet
              // built) — don't invent fake remote sessions with a dead Revoke.
              _buildSessionTile(
                device: 'This device',
                location: 'Signed in',
                lastActive: 'Current session',
                isCurrent: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Sign-in on other devices will appear here once multi-device '
                  'session management is available.',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 30),
            _sectionHeader('Login Activity'),
            _buildSettingsGroup([
              _buildInfoRow(
                label: 'Last Login',
                value: _lastLoginStr.isEmpty ? 'This session' : _lastLoginStr,
                icon: Icons.access_time,
              ),
              _buildInfoRow(
                label: 'Device',
                value: 'This device',
                icon: Icons.phone_android_outlined,
              ),
            ]),

            const SizedBox(height: 30),
            _sectionHeader('Privacy'),
            _buildSettingsGroup([
              _buildToggleRow(
                label: 'Show online status',
                icon: Icons.visibility_outlined,
                value: _onlineStatus,
                onChanged: (v) {
                  setState(() => _onlineStatus = v);
                  _setPref(_keyOnlineStatus, v);
                },
                subtitle: 'Let team members see when you are active',
              ),
              _buildToggleRow(
                label: 'Read receipts',
                icon: Icons.done_all_outlined,
                value: _readReceipts,
                onChanged: (v) {
                  setState(() => _readReceipts = v);
                  _setPref(_keyReadReceipts, v);
                },
                subtitle: 'Show when you have read messages',
              ),
              _buildToggleRow(
                label: 'Profile visibility',
                icon: Icons.person_outline,
                value: _profileVisible,
                onChanged: (v) {
                  setState(() => _profileVisible = v);
                  _setPref(_keyProfileVisible, v);
                },
                subtitle: 'Visible to team members',
              ),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Visual primitives ──────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.film, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.filmDim.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.04),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.filmDim.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleChangePassword,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Update Password',
              style: TextStyle(
                fontFamily: AppText.body.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.voidBlack,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.filmDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.film, fontSize: 15),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Active sessions are still a backend placeholder (no session-list /
  // revoke endpoint yet), so we can't actually kill a remote session. Be
  // honest: confirm the intent, then tell the user it's not live yet instead
  // of silently doing nothing or faking a "revoked" state.
  Future<void> _confirmRevoke(String device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidLight,
        title: const Text(
          'Revoke session?',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'Sign out "$device" from your account?',
          style: const TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Revoke',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remote sign-out is coming soon.'),
      ),
    );
  }

  Widget _buildSessionTile({
    required String device,
    required String location,
    required String lastActive,
    required bool isCurrent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCurrent ? Icons.phone_android : Icons.computer,
              color: isCurrent ? AppColors.accent : AppColors.filmDim,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device,
                      style: const TextStyle(
                        color: AppColors.film,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontFamily: AppText.sectionTitle.fontFamily,
                            fontSize: 8,
                            color: AppColors.green,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$location · $lastActive',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => _confirmRevoke(device),
              child: Text(
                'Revoke',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.filmDim, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.filmDim, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.film,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPwCtrl.text.trim();
    final newPw = _newPwCtrl.text.trim();
    final confirm = _confirmPwCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }
    if (newPw.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }
    if (newPw != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    try {
      await ref.read(apiClientProvider).post(
        '/api/auth/change-password',
        body: {'currentPassword': current, 'newPassword': newPw},
      );
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _showSnack('Password updated successfully');
    } catch (e) {
      _showSnack('Could not update password. Check your current password.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: AppColors.film, fontSize: 13),
          ),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
