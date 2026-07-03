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

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

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
        data: (stats) => _StatsGrid(stats: stats),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTile>[
      _StatTile('Total Users', stats.totalUsers, Icons.people_outline, AppColors.orange),
      _StatTile('Studio Owners', stats.owners, Icons.storefront_outlined, AppColors.teal),
      _StatTile('Freelancers', stats.freelancers, Icons.badge_outlined, AppColors.gold),
      _StatTile('Admins', stats.admins, Icons.shield_outlined, AppColors.accent),
      _StatTile('Total Clients', stats.totalClients, Icons.groups_outlined, AppColors.orange),
      _StatTile('Active Broadcasts', stats.activeBroadcasts, Icons.campaign_outlined, AppColors.teal),
      _StatTile('Open Tickets', stats.openTickets, Icons.support_agent_outlined, AppColors.gold),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => _StatCard(tile: tiles[i]),
    );
  }
}

class _StatTile {
  const _StatTile(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.tile});
  final _StatTile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tile.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(tile.icon, color: tile.color, size: 20),
          ),
          const Spacer(),
          Text(
            '${tile.value}',
            style: TextStyle(
              fontFamily: AppText.brandFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.film,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tile.label,
            style: TextStyle(color: AppColors.filmDim, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
