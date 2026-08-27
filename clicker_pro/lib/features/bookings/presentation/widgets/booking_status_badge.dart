// lib/features/bookings/presentation/widgets/booking_status_badge.dart
//
// Status pill rendered on every booking list row, calendar day cell,
// detail header, and timeline entry. The status-color contract is
// pinned by Requirement 1.13 and re-used across multiple screens, so
// the mapping lives here as the single source of truth.
//
// Visual tokens come exclusively from `AppColors`; no new color is
// introduced. Typography uses the existing `Inter` chain via the
// inherited theme.

import 'package:flutter/material.dart';

import '../../../../core/booking_status/booking_status.dart';
import '../../../../theme/app_colors.dart';

/// Compact status indicator shown next to booking titles.
///
/// The pill is intentionally small (height 22) so it fits inside list
/// rows without breaking single-line layouts. Use [size] = [BadgeSize.lg]
/// inside the booking detail header where extra prominence is wanted.
class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge(this.status, {super.key, this.size = BadgeSize.sm});

  final BookingStatus status;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(status);
    final isLarge = size == BadgeSize.lg;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border, width: 1),
      ),
      child: Text(
        _labelFor(status),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: tone.foreground,
          fontSize: isLarge ? 12 : 10.5,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

enum BadgeSize { sm, lg }

/// Visual tokens for one status. Built via [_toneFor] so the contract
/// stays in lockstep with the design's status-color matrix.
class _StatusTone {
  const _StatusTone({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

_StatusTone _toneFor(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
    case BookingStatus.confirmed:
    case BookingStatus.inProgress:
      return _StatusTone(
        background: AppColors.infoTeal.withValues(alpha: 0.18),
        foreground: AppColors.infoTeal,
        border: AppColors.infoTeal.withValues(alpha: 0.45),
      );
    case BookingStatus.shotComplete:
    case BookingStatus.delivered:
    case BookingStatus.completed:
      return _StatusTone(
        background: AppColors.sageData.withValues(alpha: 0.18),
        foreground: AppColors.sageData,
        border: AppColors.sageData.withValues(alpha: 0.45),
      );
    case BookingStatus.cancelled:
      return _StatusTone(
        background: AppColors.red.withValues(alpha: 0.18),
        foreground: AppColors.red,
        border: AppColors.red.withValues(alpha: 0.45),
      );
  }
}

/// Display label for a status in upper case. Intentionally hard-coded
/// English in this slice — ARB localization (Wave 10) will swap this
/// for `AppLocalizations.of(context).booking_status_<name>`.
String _labelFor(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 'PENDING';
    case BookingStatus.confirmed:
      return 'CONFIRMED';
    case BookingStatus.inProgress:
      return 'IN PROGRESS';
    case BookingStatus.shotComplete:
      return 'SHOT COMPLETE';
    case BookingStatus.delivered:
      return 'DELIVERED';
    case BookingStatus.completed:
      return 'COMPLETED';
    case BookingStatus.cancelled:
      return 'CANCELLED';
  }
}
/// Public helper for callers that want only the indicator dot color
/// (calendar day cells, timeline pending dot, etc.). Keeps the
/// status-color contract centralized.
Color statusDotColor(BookingStatus status) => _toneFor(status).foreground;
