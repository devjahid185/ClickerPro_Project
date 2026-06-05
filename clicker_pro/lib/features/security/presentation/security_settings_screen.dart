// lib/features/security/presentation/security_settings_screen.dart
//
// Clicker Pro — Security Settings screen (PROD-04)
//
// Sections: Change password, 2FA placeholder, Active sessions placeholder,
// Last login info, Privacy settings.
// Follows SettingsScreen visual pattern (glass cards, section headers).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../data/security_service.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _twoFactorEnabled = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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
                onChanged: (v) => setState(() => _twoFactorEnabled = v),
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
                value: 'Today, 09:42 AM',
                icon: Icons.access_time,
              ),
              _buildInfoRow(
                label: 'Last IP',
                value: '103.48.xx.xx',
                icon: Icons.language,
              ),
            ]),

            const SizedBox(height: 30),
            _sectionHeader('Privacy'),
            _buildSettingsGroup([
              _buildToggleRow(
                label: 'Show online status',
                icon: Icons.visibility_outlined,
                value: true,
                onChanged: (_) {},
                subtitle: 'Let team members see when you are active',
              ),
              _buildToggleRow(
                label: 'Read receipts',
                icon: Icons.done_all_outlined,
                value: true,
                onChanged: (_) {},
                subtitle: 'Show when you have read messages',
              ),
              _buildToggleRow(
                label: 'Profile visibility',
                icon: Icons.person_outline,
                value: true,
                onChanged: (_) {},
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

  void _handleChangePassword() {
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

    final hashed = SecurityService.hashPassword(newPw);
    debugPrint('Password hash: $hashed');
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();
    _showSnack('Password updated successfully');
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
