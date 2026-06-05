// lib/features/reports/presentation/widgets/team_performance_section.dart
//
// Leaderboard list — each row carries a member's name, role, event
// count, earnings, pending re-edit count, and the composite score।
// Performance score is shown as a chip on the right; the order of the
// list itself encodes the ranking (descending by score, server-side)।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/states/lens_loader.dart';
import '../../../../theme/app_colors.dart';
import '../../../settings/application/language_controller.dart';
import '../../application/reports_providers.dart';
import '../../domain/team_performance_entry.dart';

class TeamPerformanceSection extends ConsumerWidget {
  const TeamPerformanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = ref.watch(activeLocaleProvider).languageCode == 'bn'
        ? 'bn'
        : 'en';
    final year = ref.watch(selectedYearProvider);
    final async = ref.watch(teamPerformanceProvider(year));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.reports_team_section,
            style: const TextStyle(
              color: AppColors.gold,
              fontFamily: 'Poppins',
              fontSize: 14,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: LensLoader(size: 22)),
            ),
            error: (_, _) => Text(
              loc.reports_team_load_failed,
              style: const TextStyle(color: AppColors.red, fontSize: 13),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    loc.reports_team_empty,
                    style: const TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      const Divider(color: AppColors.hairline, height: 1),
                    _Row(entry: entries[i], rank: i + 1, lang: lang, loc: loc),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.rank,
    required this.lang,
    required this.loc,
  });

  final TeamPerformanceEntry entry;
  final int rank;
  final String lang;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank pill
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.gold : AppColors.glassHover,
              shape: BoxShape.circle,
              border: Border.all(
                color: rank == 1 ? AppColors.gold : AppColors.glassBorder,
              ),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1 ? AppColors.voidBlack : AppColors.filmDim,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name.isEmpty ? '—' : entry.name,
                  style: const TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _Chip(
                      label: '${entry.totalEvents} ${loc.reports_team_events}',
                      colour: AppColors.indigo,
                    ),
                    _Chip(
                      label: BookingFormat.money(
                        entry.totalEarnings,
                        lang: lang,
                        bnNumerals: lang == 'bn',
                      ),
                      colour: AppColors.green,
                    ),
                    if (entry.pendingReEdits > 0)
                      _Chip(
                        label:
                            '${entry.pendingReEdits} ${loc.reports_team_pending_reedits}',
                        colour: AppColors.yellow,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: entry.performanceScore < 0
                  ? AppColors.redSoft
                  : AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: entry.performanceScore < 0
                    ? AppColors.red
                    : AppColors.orangeGlow,
              ),
            ),
            child: Text(
              '${entry.performanceScore}',
              style: TextStyle(
                color: entry.performanceScore < 0
                    ? AppColors.red
                    : AppColors.orange,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: colour,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
