// lib/features/admin/presentation/admin_bugs_screen.dart
//
// Crash / bug console: every uncaught error the apps (mobile/Flutter web) and
// the landing page reported to /api/crash-reports, newest and unresolved
// first. Each card shows WHERE (platform badge), WHAT (error message), and —
// when expanded — WHY (stack trace + breadcrumbs). Admin can mark resolved or
// delete. Read + manage only; the data is produced by the client error hooks.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/admin_providers.dart';
import '../domain/admin_crash_report.dart';

class AdminBugsScreen extends ConsumerWidget {
  const AdminBugsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCrashReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        titleSpacing: 8,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIAGNOSTICS',
              style: TextStyle(
                fontFamily: AppText.monoFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Crashes & Bugs',
              style: TextStyle(
                color: AppColors.film,
                fontFamily: AppText.brandFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminCrashReportsProvider.future),
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              ErrorState(
                message: 'Failed to load crash reports',
                onRetry: () => ref.invalidate(adminCrashReportsProvider),
              ),
            ],
          ),
          data: (reports) => reports.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.verified_outlined,
                      message: 'No crashes reported.\nEverything looks healthy.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _BugCard(report: reports[i]),
                ),
        ),
      ),
    );
  }
}

class _BugCard extends ConsumerStatefulWidget {
  const _BugCard({required this.report});
  final AdminCrashReport report;

  @override
  ConsumerState<_BugCard> createState() => _BugCardState();
}

class _BugCardState extends ConsumerState<_BugCard> {
  bool _expanded = false;
  bool _busy = false;

  AdminCrashReport get r => widget.report;

  Future<void> _toggleResolved() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiProvider)
          .resolveCrashReport(r.id, resolved: !r.resolved);
      ref.invalidate(adminCrashReportsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete report?'),
        content: const Text('This crash report will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).deleteCrashReport(r.id);
      ref.invalidate(adminCrashReportsProvider);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _platformBadge(r.platform);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.resolved
              ? AppColors.line(0.06)
              : AppColors.red.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row: platform + resolved state + time.
                  Row(
                    children: [
                      _Chip(label: badge.label, color: badge.color, icon: badge.icon),
                      const SizedBox(width: 8),
                      if (r.resolved)
                        _Chip(
                          label: 'RESOLVED',
                          color: AppColors.green,
                          icon: Icons.check_circle_outline,
                        )
                      else
                        _Chip(
                          label: 'OPEN',
                          color: AppColors.red,
                          icon: Icons.error_outline,
                        ),
                      const Spacer(),
                      Text(
                        _timeAgo(r.createdAt),
                        style: TextStyle(
                          color: AppColors.filmMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // WHAT: the error message.
                  Text(
                    r.error,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: AppColors.filmMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          r.who + (r.appVersion != null ? ' · v${r.appVersion}' : ''),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.filmDim,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.filmMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // WHY: stack trace + breadcrumbs, shown when expanded.
          if (_expanded) ...[
            Divider(height: 1, color: AppColors.line(0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.breadcrumbs.isNotEmpty) ...[
                    _sectionLabel('LEADING ACTIONS'),
                    const SizedBox(height: 6),
                    for (final b in r.breadcrumbs.reversed.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• ${b.message}',
                          style: TextStyle(
                            color: AppColors.filmDim,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (r.stackTrace != null) ...[
                    Row(
                      children: [
                        _sectionLabel('STACK TRACE'),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: r.stackTrace!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Stack trace copied')),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.copy_outlined,
                                size: 15, color: AppColors.filmMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.appBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line(0.06)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          r.stackTrace!,
                          style: TextStyle(
                            fontFamily: AppText.monoFontFamily,
                            fontSize: 10.5,
                            height: 1.4,
                            color: AppColors.filmDim,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Actions.
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _toggleResolved,
                          icon: Icon(
                            r.resolved ? Icons.undo : Icons.check,
                            size: 16,
                          ),
                          label: Text(r.resolved ? 'Reopen' : 'Mark resolved'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                r.resolved ? AppColors.filmDim : AppColors.orange,
                            side: BorderSide(
                              color: (r.resolved
                                      ? AppColors.filmMuted
                                      : AppColors.orange)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _busy ? null : _delete,
                        tooltip: 'Delete',
                        icon: Icon(Icons.delete_outline, color: AppColors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: AppText.monoFontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.filmMuted,
        ),
      );
}

/// Platform badge styling. Distinct colours so an admin can scan by surface.
({String label, Color color, IconData icon}) _platformBadge(String platform) {
  switch (platform.toLowerCase()) {
    case 'android':
      return (label: 'ANDROID', color: AppColors.green, icon: Icons.android);
    case 'ios':
      return (label: 'IOS', color: AppColors.filmDim, icon: Icons.phone_iphone);
    case 'web':
      return (label: 'WEB APP', color: AppColors.info, icon: Icons.language);
    case 'landing':
      return (label: 'LANDING', color: AppColors.purple, icon: Icons.web_asset);
    default:
      return (label: platform.toUpperCase(), color: AppColors.gold, icon: Icons.help_outline);
  }
}

/// Compact "time ago" — the console cares about recency, not exact times.
String _timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
  return '${(d.inDays / 365).floor()}y ago';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppText.monoFontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
