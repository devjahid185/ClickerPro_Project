// lib/features/audit/presentation/audit_log_screen.dart
//
// Clicker Pro — Audit Log Viewer (Dark Luxury Lens)
//
// Displays audit trail with filtering by action type and date range.
// Each entry shows actor name, action, entity, timestamp, and diff view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../data/audit_repository_impl.dart';
import '../domain/audit_log.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AuditAction? _selectedAction;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  List<AuditLogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await ref
          .read(auditRepositoryProvider)
          .getEntries(
            action: _selectedAction,
            from: _selectedDateRange?.start,
            to: _selectedDateRange?.end,
          );
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load audit log');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Audit Log',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : _entries.isEmpty
                ? _buildEmptyState()
                : _buildEntryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.voidLight,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Action filter chips
          Row(
            children: [
              _buildFilterChip('All', null),
              const SizedBox(width: 6),
              _buildFilterChip('Create', AuditAction.create),
              const SizedBox(width: 6),
              _buildFilterChip('Update', AuditAction.update),
              const SizedBox(width: 6),
              _buildFilterChip('Delete', AuditAction.delete),
              const SizedBox(width: 6),
              _buildFilterChip('Perm', AuditAction.permission),
            ],
          ),
          const SizedBox(height: 8),
          // Date range
          Row(
            children: [
              Icon(
                Icons.date_range_outlined,
                color: AppColors.filmDim,
                size: 18,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: AppColors.pillChipDecoration(),
                  child: Text(
                    _selectedDateRange != null
                        ? '${_formatShortDate(_selectedDateRange!.start)} — ${_formatShortDate(_selectedDateRange!.end)}'
                        : 'Any date',
                    style: const TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedDateRange = null;
                    _loadEntries();
                  }),
                  child: Icon(
                    Icons.close,
                    color: AppColors.filmMuted,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AuditAction? action) {
    final selected = _selectedAction == action;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAction = action;
        _loadEntries();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.4)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.teal : AppColors.filmDim,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No audit entries',
            style: TextStyle(color: AppColors.filmDim, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Activity will appear here as changes are made',
            style: TextStyle(color: AppColors.filmMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildEntryTile(entry);
      },
    );
  }

  Widget _buildEntryTile(AuditLogEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: AppColors.iconWrapDecoration(
                  _actionColor(entry.action).withValues(alpha: 0.15),
                ),
                child: Icon(
                  _actionIcon(entry.action),
                  color: _actionColor(entry.action),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.film, fontSize: 13),
                    children: [
                      TextSpan(
                        text: entry.actorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' ${entry.actionVerb} ',
                        style: TextStyle(color: AppColors.filmDim),
                      ),
                      TextSpan(
                        text: entry.entityLabel ?? entry.entityType,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                _formatTime(entry.createdAt),
                style: TextStyle(color: AppColors.filmMuted, fontSize: 11),
              ),
            ],
          ),
          // Diff view for updates
          if (entry.action == AuditAction.update &&
              entry.before != null &&
              entry.after != null) ...[
            const SizedBox(height: 10),
            _buildDiffView(entry.before!, entry.after!),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffView(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    final changedKeys = <String>{};
    for (final key in after.keys) {
      if (before[key]?.toString() != after[key]?.toString()) {
        changedKeys.add(key);
      }
    }

    if (changedKeys.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.voidBlack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: changedKeys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key: ',
                  style: TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Expanded(
                  child: Text(
                    '${before[key]} → ${after[key]}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              surface: AppColors.voidElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
      _loadEntries();
    }
  }

  Color _actionColor(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return AppColors.green;
      case AuditAction.update:
        return AppColors.teal;
      case AuditAction.delete:
        return AppColors.red;
      case AuditAction.permission:
        return AppColors.gold;
    }
  }

  IconData _actionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return Icons.add_circle_outline;
      case AuditAction.update:
        return Icons.edit_outlined;
      case AuditAction.delete:
        return Icons.delete_outline;
      case AuditAction.permission:
        return Icons.lock_outline;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }

  String _formatShortDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
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
