import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/booking_status/booking_status.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_filter.dart';
import '../data/calendar_sync_service.dart';
import '../../../theme/app_theme.dart';

class CalendarSyncSettings extends ConsumerStatefulWidget {
  const CalendarSyncSettings({super.key});

  @override
  ConsumerState<CalendarSyncSettings> createState() =>
      _CalendarSyncSettingsState();
}

class _CalendarSyncSettingsState extends ConsumerState<CalendarSyncSettings> {
  static const _keyAutoSync = 'calendar_auto_sync';
  // Auto-sync defaults ON so a freshly created booking lands in the device
  // calendar silently, with no manual "Save" step.
  bool _autoSync = true;
  String? _lastSyncTime;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSync = prefs.getBool(_keyAutoSync) ?? true;
      _lastSyncTime = prefs.getString('calendar_last_sync');
    });
  }

  Future<void> _toggleAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, value);
    setState(() => _autoSync = value);
  }

  /// Writes every upcoming confirmed booking straight into the device
  /// calendar — a silent bulk version of the per-booking auto-sync. No share
  /// sheet, no ICS file, no Google web page: [openGoogleCalendar] with
  /// `allowWebFallback: false` just adds each event via device_calendar.
  Future<void> _syncAllConfirmed() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final bookings =
          await ref.read(bookingListAllProvider(const BookingFilter()).future);

      final today = DateTime.now();
      final cutoff = DateTime(today.year, today.month, today.day);
      final confirmed = bookings.where((b) {
        if (b.status != BookingStatus.confirmed) return false;
        return !b.date.isBefore(cutoff); // today or later only
      }).toList();

      if (confirmed.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No upcoming confirmed bookings to sync')),
        );
        return;
      }

      var added = 0;
      for (final b in confirmed) {
        final ok = await CalendarSyncService.openGoogleCalendar(
          title: b.title,
          date: b.date,
          startTime: b.startTime,
          endTime: b.endTime,
          venue: b.venue,
          description: _describe(b),
          allowWebFallback: false, // silent bulk — never yank to a browser
        );
        if (ok) added++;
      }

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final timestamp =
          '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      await prefs.setString('calendar_last_sync', timestamp);
      if (mounted) setState(() => _lastSyncTime = timestamp);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            added == confirmed.length
                ? 'Synced $added booking${added == 1 ? '' : 's'} to your calendar'
                : 'Synced $added of ${confirmed.length} — check calendar permission',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Calendar sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _describe(Booking b) => [
        if (b.clientName != null) 'Client: ${b.clientName}',
        if (b.clientPhone != null) 'Phone: ${b.clientPhone}',
        'Booked via GRAPHY7',
      ].join('\n');

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
          'Calendar Sync',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAutoSyncToggle(),
            const SizedBox(height: 16),
            _buildSyncAllButton(),
            const SizedBox(height: 16),
            _buildLastSyncCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoSyncToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _autoSync
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : AppColors.glass,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.sync,
              color: _autoSync ? AppColors.teal : AppColors.filmDim,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-sync',
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _autoSync
                      ? 'Confirmed bookings sync automatically'
                      : 'Disabled',
                  style: TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoSync,
            onChanged: _toggleAutoSync,
            activeThumbColor: AppColors.teal,
            activeTrackColor: AppColors.tealSoft,
            inactiveThumbColor: AppColors.filmMuted,
            inactiveTrackColor: AppColors.glass,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncAllButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _syncing ? null : _syncAllConfirmed,
        icon: _syncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              )
            : Icon(Icons.sync_outlined, color: AppColors.teal, size: 18),
        label: Text(
          _syncing ? 'Syncing…' : 'Sync All Confirmed',
          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.tealGlow),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLastSyncCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.glassCardDecoration(),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppColors.filmDim, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAST SYNC',
                style: TextStyle(
                  color: AppColors.teal,
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 10,
                  letterSpacing: 1.95,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _lastSyncTime ?? 'Never',
                style: TextStyle(
                  color: _lastSyncTime != null
                      ? AppColors.film
                      : AppColors.filmMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
