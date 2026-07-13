import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/format/currency.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../data/widget_service.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  WidgetService? _service;
  bool _showEventsCount = true;
  bool _showDueAmount = true;
  bool _showNextEvent = true;
  WidgetRefreshInterval _refreshInterval = WidgetRefreshInterval.thirtyMinutes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = WidgetService(prefs);
    setState(() {
      _service = service;
      _showEventsCount = service.showEventsCount;
      _showDueAmount = service.showDueAmount;
      _showNextEvent = service.showNextEvent;
      _refreshInterval = service.refreshInterval;
    });
  }

  Future<void> _save() async {
    if (_service == null) return;
    await _service!.setShowEventsCount(_showEventsCount);
    await _service!.setShowDueAmount(_showDueAmount);
    await _service!.setShowNextEvent(_showNextEvent);
    await _service!.setRefreshInterval(_refreshInterval);
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
          'Home Widget',
          style: AppText.brand.copyWith(color: AppColors.film),
        ),
      ),
      body: _service == null
          ? Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('WIDGET CONTENT', style: AppText.sectionTitle),
                  const SizedBox(height: AppSpacing.md),
                  _buildToggle(
                    'Show events count',
                    _showEventsCount,
                    (v) => setState(() {
                      _showEventsCount = v;
                      _save();
                    }),
                  ),
                  _buildToggle(
                    'Show due amount',
                    _showDueAmount,
                    (v) => setState(() {
                      _showDueAmount = v;
                      _save();
                    }),
                  ),
                  _buildToggle(
                    'Show next event',
                    _showNextEvent,
                    (v) => setState(() {
                      _showNextEvent = v;
                      _save();
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('REFRESH INTERVAL', style: AppText.sectionTitle),
                  const SizedBox(height: AppSpacing.md),
                  _buildRefreshPicker(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('SETUP', style: AppText.sectionTitle),
                  const SizedBox(height: AppSpacing.md),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WIDGET PREVIEW',
            style: AppText.metricLabel.copyWith(color: AppColors.teal),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.voidLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: AppDecorations.iconWrap(AppColors.tealSoft),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.teal,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Graphy7',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_showEventsCount)
                  _buildPreviewRow(Icons.event, 'Events today', '3'),
                if (_showDueAmount)
                  _buildPreviewRow(
                    Icons.payments, 'Due', ActiveCurrency.value.wrap('2,400')),
                if (_showNextEvent)
                  _buildPreviewRow(
                    Icons.arrow_forward_ios,
                    'Next',
                    'Wedding — 16:00',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.filmDim),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: AppText.bodyDim.copyWith(fontSize: 13)),
          ),
          Text(
            value,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.film,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecorations.glassCard(radius: AppRadius.sm),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.teal,
            activeTrackColor: AppColors.tealSoft,
            inactiveTrackColor: AppColors.glass,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshPicker() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.glassCard(radius: AppRadius.sm),
      child: Column(
        children: WidgetRefreshInterval.values.map((interval) {
          final isSelected = _refreshInterval == interval;
          return ListTile(
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.teal : AppColors.film,
              size: 20,
            ),
            title: Text(
              interval == WidgetRefreshInterval.thirtyMinutes
                  ? 'Every 30 minutes'
                  : interval == WidgetRefreshInterval.oneHour
                  ? 'Every hour'
                  : 'Manual only',
              style: AppText.body.copyWith(
                color: isSelected ? AppColors.teal : AppColors.film,
              ),
            ),
            onTap: () {
              setState(() {
                _refreshInterval = interval;
                _save();
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.glassCard(radius: AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1. Long-press the home screen\n'
            '2. Tap "Widgets"\n'
            '3. Find "Graphy7" in the list\n'
            '4. Drag the widget to your home screen',
            style: AppText.bodyDim.copyWith(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'iOS',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1. Long-press the home screen\n'
            '2. Tap the "+" button\n'
            '3. Search for "Graphy7"\n'
            '4. Add the widget to your home screen',
            style: AppText.bodyDim.copyWith(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
