// lib/features/admin/presentation/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../../core/role/role_policy.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../profile/application/profile_controllers.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final policy = ref.watch(rolePolicyProvider);
    final name = user?.name ?? 'Admin';
    final roleLabel = user?.role.displayLabel ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Admin Panel',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(name, roleLabel),
            const SizedBox(height: 24),
            _buildSectionTitle('System tools'),
            const SizedBox(height: 16),
            _buildActionsGrid(context, policy),
            const SizedBox(height: 24),
            _buildInfoCard(
              'This screen is for system-level tools only — bookings, team and '
              'finance stay on the main dashboard. User accounts, plans and '
              'platform broadcasts are managed from the web admin console.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(String name, String roleLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.filmDim.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $name',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: AppText.brandFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roleLabel.toUpperCase(),
            style: TextStyle(
              color: AppColors.accent,
              fontFamily: AppText.sectionTitle.fontFamily,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'System tools for this device — diagnostics, activity history and local backups.',
            style: TextStyle(
              color: AppColors.filmDim,
              fontFamily: AppText.body.fontFamily,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.film,
        fontFamily: AppText.brandFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context, RolePolicy policy) {
    final items = <_AdminActionItem>[
      _AdminActionItem(
        icon: Icons.history_edu_outlined,
        label: 'Audit Log',
        description: 'Inspect recent account activity.',
        routeName: RouteNames.auditLog,
        visible: policy.can(Capability.viewFinancials),
      ),
      _AdminActionItem(
        icon: Icons.bug_report_outlined,
        label: 'Crash Reports',
        description: 'Monitor app stability and issues.',
        routeName: RouteNames.crashSettings,
        visible: policy.can(Capability.viewFinancials),
      ),
      _AdminActionItem(
        icon: Icons.backup_outlined,
        label: 'Backup & Restore',
        description: 'Export or restore your studio data.',
        routeName: RouteNames.backup,
        visible: policy.can(Capability.viewFinancials),
      ),
      _AdminActionItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        description: 'App preferences and studio configuration.',
        routeName: RouteNames.settings,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: items
          .where((item) => item.visible)
          .map((item) {
            return _buildActionTile(context, item);
          })
          .toList(growable: false),
    );
  }

  Widget _buildActionTile(BuildContext context, _AdminActionItem item) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, item.routeName),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                item.label,
                style: TextStyle(
                  color: AppColors.film,
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: TextStyle(
                  color: AppColors.filmDim,
                  fontFamily: AppText.body.fontFamily,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line(0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.filmDim,
          fontFamily: AppText.body.fontFamily,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

class _AdminActionItem {
  const _AdminActionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.routeName,
    this.visible = true,
  });

  final IconData icon;
  final String label;
  final String description;
  final String routeName;
  final bool visible;
}
