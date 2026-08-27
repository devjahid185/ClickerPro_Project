// lib/features/crash_reporting/presentation/crash_settings_screen.dart
//
// Graphy7 — Crash Reporting Settings (Dark Luxury Lens)
//
// Toggle crash reporting on/off, view last crash count, send test crash (dev only).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../data/crash_service.dart';
import '../../../theme/app_theme.dart';

class CrashSettingsScreen extends ConsumerStatefulWidget {
  const CrashSettingsScreen({super.key});

  @override
  ConsumerState<CrashSettingsScreen> createState() =>
      _CrashSettingsScreenState();
}

class _CrashSettingsScreenState extends ConsumerState<CrashSettingsScreen> {
  late bool _crashReportingEnabled;
  late int _lastCrashCount;

  @override
  void initState() {
    super.initState();
    final svc = ref.read(crashServiceProvider);
    _crashReportingEnabled = svc.enabled;
    _lastCrashCount = svc.crashCount;
  }

  void _toggleCrashReporting(bool value) {
    ref.read(crashServiceProvider).setEnabled(value);
    setState(() => _crashReportingEnabled = value);
  }

  Future<void> _sendTestCrash() async {
    try {
      throw Exception('Test crash from CrashSettingsScreen');
    } catch (e, st) {
      await ref.read(crashServiceProvider).recordError(e, st);
      if (!mounted) return;
      setState(
        () => _lastCrashCount = ref.read(crashServiceProvider).crashCount,
      );
      _showSnack('Test crash recorded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Crash Reporting',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Settings'),
            _buildActionGroup([
              _buildToggleRow(
                label: 'Crash Reporting',
                icon: Icons.bug_report_outlined,
                value: _crashReportingEnabled,
                onChanged: _toggleCrashReporting,
              ),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Status'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppColors.glassCardDecoration(),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: AppColors.iconWrapDecoration(
                      AppColors.teal.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported Crashes',
                          style: TextStyle(
                            color: AppColors.filmDim,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_lastCrashCount',
                          style: TextStyle(
                            color: AppColors.film,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Development'),
            _buildActionGroup([
              _buildActionButton(
                icon: Icons.send_outlined,
                label: 'Send Test Crash',
                onTap: _sendTestCrash,
                color: AppColors.gold,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> children) {
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

  Widget _buildToggleRow({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
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
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color ?? AppColors.teal, size: 22),
        title: Text(
          label,
          style: TextStyle(color: AppColors.film, fontSize: 15),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.filmMuted,
          size: 20,
        ),
        onTap: onTap,
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
