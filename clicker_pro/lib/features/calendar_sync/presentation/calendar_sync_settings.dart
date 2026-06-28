import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../data/calendar_sync_service.dart';
import '../domain/calendar_event.dart';

class CalendarSyncSettings extends StatefulWidget {
  const CalendarSyncSettings({super.key});

  @override
  State<CalendarSyncSettings> createState() => _CalendarSyncSettingsState();
}

class _CalendarSyncSettingsState extends State<CalendarSyncSettings> {
  static const _keyAutoSync = 'calendar_auto_sync';
  // Auto-sync defaults ON so a freshly created booking lands in the device
  // calendar silently, with no manual "Save" step.
  bool _autoSync = true;
  String? _lastSyncTime;

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

  Future<void> _syncAllConfirmed() async {
    final now = DateTime.now();
    final event = CalendarEvent(
      title: 'Clicker Pro — Demo Sync',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 4)),
      description: 'Auto-synced confirmed bookings.',
      location: 'TBD',
    );

    await CalendarSyncService.shareCalendarEvent(event);

    final prefs = await SharedPreferences.getInstance();
    final timestamp =
        '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await prefs.setString('calendar_last_sync', timestamp);
    setState(() => _lastSyncTime = timestamp);
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
          'Calendar Sync',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
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
        onPressed: _syncAllConfirmed,
        icon: Icon(Icons.sync_outlined, color: AppColors.teal, size: 18),
        label: Text(
          'Sync All Confirmed',
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
                  fontFamily: 'Montserrat',
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
