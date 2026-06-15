// lib/features/freelancer/presentation/fl_checkin_screen.dart
//
// Freelancer Live Check-In screen (FL-09).
// "I'm Here" button on event day; owner sees real-time status.
// Late arrivals trigger a notification alert.
//
// Layout:
//
//   ┌─────────────────────────────────────┐
//   │ AppBar: ← Check-In                 │
//   ├─────────────────────────────────────┤
//   │ Event info card                     │
//   │   Company, date, time, role         │
//   ├─────────────────────────────────────┤
//   │ Status indicator                    │
//   │   Checked-in / Late / Not yet       │
//   ├─────────────────────────────────────┤
//   │ [I'm Here] button (large, teal)     │
//   └─────────────────────────────────────┘
//
// Also serves as the multi-owner dashboard entry (FL-08) when the
// freelancer has events from multiple owners on the same day.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/fl_tools_providers.dart';
import '../domain/fl_checkin.dart';

class FlCheckinScreen extends ConsumerStatefulWidget {
  const FlCheckinScreen({super.key, this.eventId, this.eventData});

  /// When provided, the screen targets a specific event.
  final String? eventId;

  /// Optional pre-loaded event metadata for display.
  final Map<String, dynamic>? eventData;

  @override
  ConsumerState<FlCheckinScreen> createState() => _FlCheckinScreenState();
}

class _FlCheckinScreenState extends ConsumerState<FlCheckinScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(flCheckinControllerProvider.notifier)
            .fetchStatus(widget.eventId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkinAsync = ref.watch(flCheckinControllerProvider);
    final conflictsAsync = ref.watch(flConflictsProvider);
    final event = widget.eventData ?? {};

    final companyName = event['companyName'] as String? ?? 'Studio';
    final eventType = event['eventType'] as String? ?? 'Event';
    final eventDate = event['date'] != null
        ? DateTime.parse(event['date'] as String)
        : DateTime.now();
    final eventTime = event['startTime'] as String? ?? '--:--';
    final role = event['role'] as String? ?? '';

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
          'Check-In',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Info Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppColors.glassCardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: AppColors.iconWrapDecoration(
                        AppColors.teal.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.event_outlined,
                        color: AppColors.teal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: TextStyle(
                              color: AppColors.film,
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$eventType · $role',
                            style: TextStyle(
                              color: AppColors.filmDim,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoChip(
                      Icons.calendar_today,
                      '${eventDate.month}/${eventDate.day}/${eventDate.year}',
                    ),
                    const SizedBox(width: 10),
                    _infoChip(Icons.access_time, eventTime),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Check-In Status ──
          checkinAsync.when(
            loading: () =>
                const SizedBox(height: 120, child: Center(child: LensLoader())),
            error: (_, _) => const SizedBox(
              height: 120,
              child: ErrorState(message: 'Could not load check-in status.'),
            ),
            data: (checkin) {
              if (checkin == null) {
                return _buildNotCheckedIn(eventTime);
              }
              return _buildCheckedInStatus(checkin);
            },
          ),

          const SizedBox(height: 24),

          // ── Conflict Warnings (FL-08) ──
          conflictsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (conflicts) {
              if (conflicts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SCHEDULE CONFLICTS',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...conflicts.map((c) => _ConflictWarning(data: c)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppColors.pillChipDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.filmMuted, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: AppColors.filmDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotCheckedIn(String eventTime) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.filmMuted.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.filmMuted.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            Icons.location_searching,
            color: AppColors.filmMuted,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Not checked in yet',
          style: TextStyle(
            color: AppColors.filmDim,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Expected at $eventTime',
          style: TextStyle(color: AppColors.filmMuted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.voidBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _handleCheckin,
            icon: const Icon(Icons.check_circle_outline, size: 22),
            label: const Text(
              "I'm Here",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckedInStatus(FlCheckin checkin) {
    final color = checkin.isLate ? AppColors.red : AppColors.green;
    final icon = checkin.isLate
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline;
    final label = checkin.isLate ? 'Late Check-In' : 'On Time';
    final timeStr =
        '${checkin.checkinTime.hour}:${checkin.checkinTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.glassCardDecoration(
        radius: 16,
        tint: color.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: AppColors.iconWrapDecoration(
              color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Checked in at $timeStr',
                  style: TextStyle(
                    color: AppColors.filmDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (checkin.isLate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppColors.pillChipDecoration(tint: AppColors.redSoft),
              child: Text(
                '${checkin.lateness.inMinutes}m late',
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCheckin() async {
    final eventId = widget.eventId ?? '';
    if (eventId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No event selected.')));
      return;
    }

    final now = DateTime.now();
    final expectedTime = widget.eventData?['date'] != null
        ? DateTime.parse(widget.eventData!['date'] as String)
        : now;

    final draft = FlCheckin(
      id: now.microsecondsSinceEpoch.toString(),
      freelancerId: '',
      eventId: eventId,
      checkinTime: now,
      expectedTime: expectedTime,
      status: now.isAfter(expectedTime.add(const Duration(minutes: 15)))
          ? CheckinStatus.late
          : CheckinStatus.checkedIn,
      createdAt: now,
    );

    try {
      await ref.read(flCheckinControllerProvider.notifier).checkin(draft);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in failed. Please try again.')),
      );
    }
  }
}

// ─── Conflict Warning ─────────────────────────────────────────────────

class _ConflictWarning extends StatelessWidget {
  const _ConflictWarning({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ownerName = data['ownerName'] as String? ?? 'Owner';
    final timeSlot = data['timeSlot'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Overlapping event with $ownerName$timeSlot',
              style: TextStyle(color: AppColors.filmDim, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
