import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../domain/fl_badge.dart';

class FlBadgesScreen extends StatefulWidget {
  const FlBadgesScreen({super.key});

  @override
  State<FlBadgesScreen> createState() => _FlBadgesScreenState();
}

class _FlBadgesScreenState extends State<FlBadgesScreen> {
  late FlBadgeSummary _summary;

  @override
  void initState() {
    super.initState();
    _summary = FlBadgeSummary(
      totalEvents: 47,
      yearsActive: 2,
      specialAchievements: 3,
      currentLevel: BadgeLevel.bronze,
      earnedBadges: [
        FlBadge(
          id: 'b1',
          name: 'Bronze Star',
          level: BadgeLevel.bronze,
          description: 'Completed 10 events',
          earnedAt: DateTime(2025, 3, 15),
          icon: '⭐',
          shareable: true,
        ),
        FlBadge(
          id: 'b2',
          name: 'First Wedding',
          level: BadgeLevel.bronze,
          description: 'Shot your first wedding event',
          earnedAt: DateTime(2025, 4, 20),
          icon: '💒',
          shareable: true,
          specialType: SpecialBadgeType.firstWedding,
        ),
        FlBadge(
          id: 'b3',
          name: 'Night Owl',
          level: BadgeLevel.bronze,
          description: 'Completed 5 night events',
          earnedAt: DateTime(2025, 6, 10),
          icon: '🦉',
          shareable: true,
          specialType: SpecialBadgeType.nightSpecialist,
        ),
        FlBadge(
          id: 'b4',
          name: 'Team Player',
          level: BadgeLevel.bronze,
          description: 'Collaborated on 10 team events',
          earnedAt: DateTime(2025, 8, 5),
          icon: '🤝',
          shareable: true,
          specialType: SpecialBadgeType.teamPlayer,
        ),
        FlBadge(
          id: 'b5',
          name: 'Early Bird',
          level: BadgeLevel.bronze,
          description: 'Checked in early 5 times',
          earnedAt: DateTime(2025, 10, 12),
          icon: '🐦',
          shareable: true,
          specialType: SpecialBadgeType.earlyBird,
        ),
        FlBadge(
          id: 'b6',
          name: 'Weekend Warrior',
          level: BadgeLevel.bronze,
          description: 'Worked 10 weekend events',
          earnedAt: DateTime(2026, 1, 8),
          icon: '⚔️',
          shareable: true,
          specialType: SpecialBadgeType.weekendWarrior,
        ),
      ],
      lockedBadges: [
        FlBadge(
          id: 'l1',
          name: 'Silver Pro',
          level: BadgeLevel.silver,
          description: 'Complete 50 events',
          earnedAt: DateTime(2026, 1, 1),
          icon: '🥈',
          shareable: true,
        ),
        FlBadge(
          id: 'l2',
          name: 'Gold Master',
          level: BadgeLevel.gold,
          description: 'Complete 100 events',
          earnedAt: DateTime(2026, 1, 1),
          icon: '🥇',
          shareable: true,
        ),
        FlBadge(
          id: 'l3',
          name: 'Platinum Elite',
          level: BadgeLevel.platinum,
          description: 'Complete 200 events',
          earnedAt: DateTime(2026, 1, 1),
          icon: '💎',
          shareable: true,
        ),
        FlBadge(
          id: 'l4',
          name: 'Marathon Runner',
          level: BadgeLevel.silver,
          description: 'Work 3 consecutive days',
          earnedAt: DateTime(2026, 1, 1),
          icon: '🏃',
          shareable: true,
          specialType: SpecialBadgeType.marathonRunner,
        ),
        FlBadge(
          id: 'l5',
          name: 'Perfect Attendance',
          level: BadgeLevel.gold,
          description: 'No missed events in a month',
          earnedAt: DateTime(2026, 1, 1),
          icon: '✅',
          shareable: true,
          specialType: SpecialBadgeType.perfectAttendance,
        ),
        FlBadge(
          id: 'l6',
          name: 'Client Favorite',
          level: BadgeLevel.gold,
          description: 'Receive 10 five-star reviews',
          earnedAt: DateTime(2026, 1, 1),
          icon: '❤️',
          shareable: true,
          specialType: SpecialBadgeType.clientFavorite,
        ),
      ],
    );
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
          'Badges',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildCurrentBadgeHero(),
          const SizedBox(height: 24),
          _buildProgressBar(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildSectionHeader('EARNED BADGES'),
          const SizedBox(height: 12),
          _buildBadgeGrid(_summary.earnedBadges, locked: false),
          const SizedBox(height: 24),
          _buildSectionHeader('LOCKED BADGES'),
          const SizedBox(height: 12),
          _buildBadgeGrid(_summary.lockedBadges, locked: true),
        ],
      ),
    );
  }

  Widget _buildCurrentBadgeHero() {
    final levelColor = _levelColor(_summary.currentLevel);
    final next = BadgeLevel.nextFor(_summary.totalEvents);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: levelColor,
              boxShadow: [
                BoxShadow(
                  color: levelColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _levelIcon(_summary.currentLevel),
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_summary.currentLevel.name[0].toUpperCase()}${_summary.currentLevel.name.substring(1)} Level',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_summary.totalEvents} events completed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.filmDim.withValues(alpha: 0.7),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              '${next.threshold - _summary.totalEvents} more to ${next.name}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: levelColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _summary.progressToNext;
    final levelColor = _levelColor(_summary.currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS TO NEXT LEVEL',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.filmMuted,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: levelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.glass,
            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('TOTAL EVENTS', '${_summary.totalEvents}', AppColors.teal),
        const SizedBox(width: 10),
        _statCard('YEARS ACTIVE', '${_summary.yearsActive}', AppColors.gold),
        const SizedBox(width: 10),
        _statCard(
          'SPECIAL',
          '${_summary.specialAchievements}',
          AppColors.purple,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.filmMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<FlBadge> badges, {required bool locked}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _BadgeTile(badge: badge, locked: locked);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.filmMuted,
      ),
    );
  }

  Color _levelColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return const Color(0xFFCD7F32);
      case BadgeLevel.silver:
        return const Color(0xFFC0C0C0);
      case BadgeLevel.gold:
        return AppColors.gold;
      case BadgeLevel.platinum:
        return AppColors.teal;
    }
  }

  String _levelIcon(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return '⭐';
      case BadgeLevel.silver:
        return '🥈';
      case BadgeLevel.gold:
        return '🥇';
      case BadgeLevel.platinum:
        return '💎';
    }
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.locked});
  final FlBadge badge;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(badge.level);
    final effectiveColor = locked ? AppColors.filmMuted : levelColor;

    return GestureDetector(
      onTap: locked ? null : () => _showBadgeDetail(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: locked ? AppColors.glass : levelColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? AppColors.glassBorder
                : levelColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: locked ? 0.3 : 1.0,
              child: Text(badge.icon, style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.voidLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.filmDim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(badge.icon, style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _levelColor(badge.level),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.filmDim.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Earned: ${_formatDate(badge.earnedAt)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.filmMuted,
              ),
            ),
            if (badge.shareable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'I earned the "${badge.name}" badge on Clicker Pro!',
                      ),
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Badge text copied to clipboard'),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: Text('Share Badge'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _levelColor(badge.level),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Color _levelColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return const Color(0xFFCD7F32);
      case BadgeLevel.silver:
        return const Color(0xFFC0C0C0);
      case BadgeLevel.gold:
        return AppColors.gold;
      case BadgeLevel.platinum:
        return AppColors.teal;
    }
  }
}
