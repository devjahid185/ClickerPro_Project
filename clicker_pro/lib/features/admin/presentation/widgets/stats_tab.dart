// lib/features/admin/presentation/widgets/stats_tab.dart
//
// Platform-wide non-financial counts. Backed by `GET /api/admin/stats`
// (Api\AdminController::stats — deliberately excludes any studio's
// booking/revenue data; see that controller's PRIVACY comments).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/states/error_state.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../application/admin_providers.dart';
import '../../domain/admin_stats.dart';
import '../admin_ticket_list_screen.dart';
import '../admin_user_list_screen.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key, required this.onOpenBroadcasts});

  /// Switches the parent `AdminHomeScreen` to the Broadcasts tab — tapping
  /// "Active Broadcasts" here should jump to that tab rather than open a
  /// second, duplicate broadcasts list.
  final VoidCallback onOpenBroadcasts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminStatsProvider.future),
      child: async.when(
        loading: () => const Center(child: LensLoader()),
        error: (err, _) => ListView(
          children: [
            const SizedBox(height: 120),
            ErrorState(
              message: 'Failed to load platform stats',
              onRetry: () => ref.invalidate(adminStatsProvider),
            ),
          ],
        ),
        data: (stats) => _StatsGrid(stats: stats, onOpenBroadcasts: onOpenBroadcasts),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.onOpenBroadcasts});
  final AdminStats stats;
  final VoidCallback onOpenBroadcasts;

  void _openUsers(BuildContext context, String title, String? role) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AdminUserListScreen(title: title, role: role)),
    );
  }

  void _openTickets(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AdminTicketListScreen()),
    );
  }

  void _totalClientsUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client list isn\'t available platform-wide yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTile>[
      _StatTile(
        'Studio Owners',
        stats.owners,
        Icons.storefront_outlined,
        AppColors.teal,
        onTap: () => _openUsers(context, 'Studio Owners', 'OWNER'),
      ),
      _StatTile(
        'Freelancers',
        stats.freelancers,
        Icons.badge_outlined,
        AppColors.gold,
        onTap: () => _openUsers(context, 'Freelancers', 'FREELANCER'),
      ),
      _StatTile(
        'Admins',
        stats.admins,
        Icons.shield_outlined,
        AppColors.accent,
        onTap: () => _openUsers(context, 'Admins', 'ADMIN'),
      ),
      _StatTile(
        'Total Clients',
        stats.totalClients,
        Icons.groups_outlined,
        AppColors.orange,
        onTap: () => _totalClientsUnavailable(context),
      ),
      _StatTile(
        'Active Broadcasts',
        stats.activeBroadcasts,
        Icons.campaign_outlined,
        AppColors.teal,
        onTap: onOpenBroadcasts,
      ),
      _StatTile(
        'Open Tickets',
        stats.openTickets,
        Icons.support_agent_outlined,
        AppColors.gold,
        onTap: () => _openTickets(context),
      ),
    ];

    return ListView(
      // Bottom padding clears the floating nav pill (64 bar + 14 inset + FAB).
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        _HeroStatCard(
          eyebrow: 'TOTAL USERS · PLATFORM',
          value: stats.totalUsers,
          caption: '${stats.owners} owners · ${stats.freelancers} freelancers',
          onTap: () => _openUsers(context, 'Total Users', null),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) => _StatCard(tile: tiles[i]),
        ),
      ],
    );
  }
}

/// The Graphy7 hero card: a solid-lime panel with a large headline number,
/// a mono eyebrow, and a supporting caption. Used for the single most
/// important platform metric (total users). Text sits in the on-accent colour
/// so it stays legible on the bright lime fill.
class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final String eyebrow;
  final int value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onLime = AppColors.onAccent;
    return Material(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    eyebrow,
                    style: TextStyle(
                      fontFamily: AppText.monoFontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: onLime.withValues(alpha: 0.72),
                    ),
                  ),
                  Icon(Icons.people_alt_rounded,
                      color: onLime.withValues(alpha: 0.85), size: 20),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: TextStyle(
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0,
                  color: onLime,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: onLime.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile {
  const _StatTile(this.label, this.value, this.icon, this.color, {required this.onTap});
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.tile});
  final _StatTile tile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: tile.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tile.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(tile.icon, color: tile.color, size: 18),
              ),
              const SizedBox(height: 14),
              Text(
                '${tile.value}',
                style: TextStyle(
                  fontFamily: AppText.brandFontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.film,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.filmDim, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
