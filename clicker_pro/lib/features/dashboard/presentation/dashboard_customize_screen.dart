// lib/features/dashboard/presentation/dashboard_customize_screen.dart
//
// Graphy7 — Dashboard Customize screen (MOD-62)
//
// Reorderable list with drag handles + toggle switches per section.
// "Reset to Default" button at bottom.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/dashboard_preferences.dart';
import '../domain/dashboard_section.dart';

class DashboardCustomizeScreen extends ConsumerWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(dashboardPrefsProvider);
    final notifier = ref.read(dashboardPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Customize Dashboard',
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
            color: AppColors.line(0.06),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              itemCount: sections.length,
              onReorderItem: (oldIndex, newIndex) {
                notifier.reorderSection(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final section = sections[index];
                return _SectionTile(
                  key: ValueKey('section-${section.type.name}'),
                  section: section,
                  onToggle: (enabled) {
                    notifier.toggleSection(section.type, enabled);
                  },
                );
              },
            ),
          ),
          _ResetButton(onPressed: () => notifier.resetToDefault()),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.section,
    required this.onToggle,
  });

  final DashboardSection section;
  final ValueChanged<bool> onToggle;

  IconData _iconFor(DashboardSectionType type) {
    switch (type) {
      case DashboardSectionType.weekStrip:
        return Icons.view_week_outlined;
      case DashboardSectionType.splitHero:
        return Icons.dashboard_outlined;
      case DashboardSectionType.deliveredBar:
        return Icons.check_circle_outline;
      case DashboardSectionType.quickActions:
        return Icons.flash_on_outlined;
      case DashboardSectionType.announcement:
        return Icons.campaign_outlined;
      case DashboardSectionType.financeRow:
        return Icons.payments_outlined;
      case DashboardSectionType.holidays:
        return Icons.celebration_outlined;
      case DashboardSectionType.weather:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: section.enabled
            ? AppColors.line(0.04)
            : AppColors.line(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: section.enabled
              ? AppColors.line(0.08)
              : AppColors.line(0.04),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: section.enabled
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.line(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _iconFor(section.type),
            color: section.enabled ? AppColors.accent : AppColors.filmDim,
            size: 18,
          ),
        ),
        title: Text(
          section.label,
          style: TextStyle(
            fontFamily: AppText.body.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: section.enabled ? AppColors.film : AppColors.filmDim,
          ),
        ),
        subtitle: Text(
          section.enabled ? 'Visible on dashboard' : 'Hidden',
          style: TextStyle(
            fontFamily: AppText.body.fontFamily,
            fontSize: 11,
            color: AppColors.filmDim.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: section.enabled,
              activeThumbColor: AppColors.accent,
              onChanged: onToggle,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.drag_handle,
              color: AppColors.filmDim.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.line(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line(0.08)),
              ),
              child: Text(
                'Reset to Default',
                style: TextStyle(
                  fontFamily: AppText.body.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
