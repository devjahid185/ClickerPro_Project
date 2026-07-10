import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../application/export_providers.dart';
import '../domain/export_config.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportControllerProvider.notifier).refreshCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Data Export', style: AppText.brand),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildSectionLabel('EXPORT FORMAT'),
            const SizedBox(height: 12),
            _buildTypeSelector(state),
            const SizedBox(height: 24),
            _buildSectionLabel('DATA SCOPE'),
            const SizedBox(height: 12),
            _buildScopeCheckboxes(state),
            const SizedBox(height: 24),
            _buildSectionLabel('DATE RANGE'),
            const SizedBox(height: 12),
            _buildDateRangeSelector(state),
            const SizedBox(height: 32),
            _buildGenerateButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.glassCard(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecorations.iconWrap(AppColors.tealSoft),
            child: Icon(
              Icons.file_download_outlined,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export your studio data',
                  style: AppText.brand.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  'Export bookings, clients, payments, and expenses — as CSV, '
                  'or straight into Google Sheets.',
                  style: AppText.bodyDim.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: AppText.sectionTitle);
  }

  ({String label, IconData icon}) _typeMeta(ExportType type) {
    switch (type) {
      case ExportType.csv:
        return (label: 'CSV', icon: Icons.table_chart_outlined);
      case ExportType.googleSheets:
        return (label: 'Sheets', icon: Icons.grid_on_outlined);
      case ExportType.pdf:
        return (label: 'PDF', icon: Icons.picture_as_pdf_outlined);
      case ExportType.zip:
        return (label: 'ZIP', icon: Icons.folder_zip_outlined);
    }
  }

  // Only the formats that actually produce their own output are offered.
  // PDF/ZIP were placeholder tiles that silently fell back to CSV, so they
  // are excluded from the picker (the enum keeps them for compatibility).
  static const _selectableTypes = [ExportType.csv, ExportType.googleSheets];

  Widget _buildTypeSelector(ExportControllerState state) {
    return Row(
      children: _selectableTypes.map((type) {
        final selected = state.type == type;
        final meta = _typeMeta(type);
        final label = meta.label;
        final icon = meta.icon;

        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(exportControllerProvider.notifier).setType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: type != ExportType.values.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration:
                  AppDecorations.glassCard(
                    radius: 12,
                    tint: selected ? AppColors.tealSoft : null,
                  ).copyWith(
                    border: Border.all(
                      color: selected ? AppColors.teal : AppColors.glassBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.teal : AppColors.filmDim,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      color: selected ? AppColors.teal : AppColors.filmDim,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScopeCheckboxes(ExportControllerState state) {
    final scopes = [
      (ExportScope.bookings, Icons.event_outlined, 'Bookings'),
      (ExportScope.clients, Icons.person_outline, 'Clients'),
      (ExportScope.payments, Icons.payments_outlined, 'Payments'),
      (ExportScope.expenses, Icons.receipt_long_outlined, 'Expenses'),
    ];

    return Container(
      decoration: AppDecorations.glassCard(),
      child: Column(
        children: scopes.asMap().entries.map((entry) {
          final index = entry.key;
          final (scope, icon, label) = entry.value;
          final selected = state.scopes.contains(scope);
          final count = state.itemCounts[scope];
          final isLast = index == scopes.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => ref
                    .read(exportControllerProvider.notifier)
                    .toggleScope(scope),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: AppDecorations.iconWrap(
                          selected ? AppColors.tealSoft : AppColors.glass,
                        ),
                        child: Icon(
                          icon,
                          color: selected ? AppColors.teal : AppColors.filmDim,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: AppText.body.copyWith(
                            color: selected
                                ? AppColors.film
                                : AppColors.filmDim,
                            fontWeight: selected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (count != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: AppDecorations.pillChip(
                            tint: selected ? AppColors.tealSoft : null,
                          ),
                          child: Text(
                            '$count',
                            style: AppText.pillChip.copyWith(
                              color: selected
                                  ? AppColors.teal
                                  : AppColors.filmMuted,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Checkbox(
                        value: selected,
                        onChanged: (_) => ref
                            .read(exportControllerProvider.notifier)
                            .toggleScope(scope),
                        activeColor: AppColors.teal,
                        checkColor: AppColors.voidBlack,
                        side: BorderSide(color: AppColors.glassBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.glassBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRangeSelector(ExportControllerState state) {
    final presets = [
      (DateRangePreset.any, 'Any'),
      (DateRangePreset.today, 'Today'),
      (DateRangePreset.thisWeek, 'This Week'),
      (DateRangePreset.thisMonth, 'This Month'),
      (DateRangePreset.custom, 'Custom'),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((entry) {
            final (preset, label) = entry;
            final selected = state.dateRangePreset == preset;
            return GestureDetector(
              onTap: () {
                if (preset == DateRangePreset.custom) {
                  _showCustomDateRangePicker(context);
                } else {
                  ref
                      .read(exportControllerProvider.notifier)
                      .setDateRangePreset(preset);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration:
                    AppDecorations.pillChip(
                      tint: selected ? AppColors.tealSoft : null,
                    ).copyWith(
                      border: Border.all(
                        color: selected
                            ? AppColors.teal
                            : AppColors.glassBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                child: Text(
                  label,
                  style: AppText.pillChip.copyWith(
                    color: selected ? AppColors.teal : AppColors.filmDim,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (state.dateRangePreset == DateRangePreset.custom) ...[
          const SizedBox(height: 12),
          _buildCustomDateRangeDisplay(state),
        ],
      ],
    );
  }

  Widget _buildCustomDateRangeDisplay(ExportControllerState state) {
    final from = state.dateRange.from;
    final to = state.dateRange.to;
    final formatter =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final toFormatter =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.glassCard(radius: 10),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AppColors.filmDim,
          ),
          const SizedBox(width: 10),
          Text(
            '$formatter  →  $toFormatter',
            style: AppText.bodyDim.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: ref.read(exportControllerProvider).dateRange.from,
        end: ref.read(exportControllerProvider).dateRange.to,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: AppColors.voidBlack,
              surface: AppColors.voidLight,
              onSurface: AppColors.film,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.voidElevated,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(exportControllerProvider.notifier)
          .setCustomDateRange(DateRange(from: picked.start, to: picked.end));
    }
  }

  Widget _buildGenerateButton(ExportControllerState state) {
    final hasScope = state.scopes.isNotEmpty;
    final isGenerating = state.generating;
    final isSheets = state.type == ExportType.googleSheets;

    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: hasScope ? AppColors.teal : AppColors.glassBorder,
          disabledBackgroundColor: AppColors.glassBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: hasScope && !isGenerating ? _onGenerate : null,
        icon: isGenerating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.film,
                ),
              )
            : Icon(
                isSheets ? Icons.grid_on_outlined : Icons.share_outlined,
                color: AppColors.film,
                size: 18,
              ),
        label: Text(
          isGenerating
              ? 'Generating...'
              : isSheets
              ? 'Export to Sheets'
              : 'Generate & Share',
          style: TextStyle(
            color: AppColors.film,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Future<void> _onGenerate() async {
    final notifier = ref.read(exportControllerProvider.notifier);
    final wasSheets =
        ref.read(exportControllerProvider).type == ExportType.googleSheets;
    final producedSheets = await notifier.generateAndShare();
    if (!mounted || !wasSheets || !producedSheets) return;
    await _showOpenSheetsPrompt();
  }

  /// After the CSV has been shared to Drive/Sheets, walk the user through
  /// the one import tap Google requires (Drive can't auto-convert on our
  /// behalf without OAuth).
  Future<void> _showOpenSheetsPrompt() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Open in Google Sheets', style: AppText.brand),
        content: Text(
          'Your data was exported as a CSV. To finish, open Google Sheets, '
          'then use File → Import (or open the CSV from Drive) to load it '
          'into a spreadsheet.',
          style: AppText.bodyDim.copyWith(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Not now', style: TextStyle(color: AppColors.filmDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Open Sheets',
              style: TextStyle(
                color: AppColors.film,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (open != true || !mounted) return;
    final ok = await ref
        .read(exportControllerProvider.notifier)
        .openGoogleSheets();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Google Sheets')),
    );
  }
}
