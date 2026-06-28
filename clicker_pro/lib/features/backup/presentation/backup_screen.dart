// lib/features/backup/presentation/backup_screen.dart
//
// Clicker Pro — Backup & Restore Screen (Dark Luxury Lens)
//
// Displays last backup timestamp, backup/restore buttons, and auto-backup toggle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../theme/app_colors.dart';
import '../data/backup_service.dart';
import '../domain/backup_record.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _autoBackupEnabled = false;
  bool _isLoading = false;
  List<BackupRecord> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await ref.read(backupServiceProvider).listBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (_) {}
  }

  Future<void> _backupNow() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final databaseContent = <String, dynamic>{
        'schemaVersion': db.schemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'note': 'Clicker Pro local database backup',
      };
      final record = await ref
          .read(backupServiceProvider)
          .exportDatabase(
            databaseContent: databaseContent,
            type: BackupType.manual,
          );
      if (!mounted) return;
      setState(() => _backups = [record, ..._backups]);
      _showSnack('Backup completed — ${record.sizeLabel}');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: Text(
          'Restore Database',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'This will replace all current data with the backup. Continue?',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Restore', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm != true || _backups.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final latest = _backups.first;
      if (latest.filePath == null) throw Exception('No backup file found');
      await ref.read(backupServiceProvider).importDatabase(latest.filePath!);
      if (!mounted) return;
      _showSnack('Database restored successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastBackup = _backups.isNotEmpty ? _backups.first : null;

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
          'Backup & Restore',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Icons.cloud_done_outlined,
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
                          'Last Backup',
                          style: TextStyle(
                            color: AppColors.filmDim,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastBackup != null
                              ? _formatDate(lastBackup.createdAt)
                              : 'No backups yet',
                          style: TextStyle(
                            color: Colors.white,
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
            _sectionHeader('Actions'),
            _buildActionGroup([
              _buildActionButton(
                icon: Icons.cloud_upload_outlined,
                label: 'Backup Now',
                onTap: _isLoading ? null : _backupNow,
                loading: _isLoading,
              ),
              _buildActionButton(
                icon: Icons.cloud_download_outlined,
                label: 'Restore',
                onTap: _isLoading || _backups.isEmpty ? null : _restore,
                color: AppColors.gold,
              ),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Auto Backup'),
            _buildActionGroup([
              _buildToggleRow(
                label: 'Automatic Backups',
                icon: Icons.schedule_outlined,
                value: _autoBackupEnabled,
                onChanged: (v) => setState(() => _autoBackupEnabled = v),
              ),
            ]),
            if (_backups.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader('History'),
              ..._backups.map((b) => _buildBackupTile(b)),
            ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    bool loading = false,
  }) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: enabled ? (color ?? AppColors.teal) : AppColors.filmMuted,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: enabled ? AppColors.film : AppColors.filmMuted,
            fontSize: 15,
          ),
        ),
        trailing: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.teal,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.chevron_right, color: AppColors.filmMuted, size: 20),
        onTap: onTap,
      ),
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
                style: TextStyle(color: Colors.white, fontSize: 15),
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

  Widget _buildBackupTile(BackupRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppColors.iconWrapDecoration(
              AppColors.tealSoft.withValues(alpha: 0.5),
            ),
            child: Icon(
              Icons.file_copy_outlined,
              color: AppColors.teal,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.type.name.toUpperCase()} Backup',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '${record.sizeLabel} · ${_formatDate(record.createdAt)}',
                  style: TextStyle(color: AppColors.filmDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            record.status == BackupStatus.completed
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: record.status == BackupStatus.completed
                ? AppColors.green
                : AppColors.red,
            size: 18,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
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
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
