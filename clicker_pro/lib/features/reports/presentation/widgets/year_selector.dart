// lib/features/reports/presentation/widgets/year_selector.dart
//
// Pill-style year selector at the top of the reports screen।  Shows
// the last 6 years + an "All time" option।  Selected pill flips to
// orange; the rest stay glass-tinted।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../application/reports_providers.dart';

class YearSelector extends ConsumerWidget {
  const YearSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selected = ref.watch(selectedYearProvider);
    final thisYear = DateTime.now().year;

    // Last 6 calendar years + an "All time" sentinel (0)
    final years = <int>[
      0, // all time
      for (int y = thisYear; y >= thisYear - 5; y--) y,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final year in years) ...[
            _YearPill(
              label: year == 0 ? loc.reports_year_all_time : year.toString(),
              selected: selected == year,
              onTap: () => ref.read(selectedYearProvider.notifier).state = year,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.filmDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
