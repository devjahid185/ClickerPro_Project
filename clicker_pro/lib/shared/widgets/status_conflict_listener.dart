// lib/shared/widgets/status_conflict_listener.dart
//
// Lightweight invisible listener that subscribes to the outbox status
// conflict stream and surfaces a non-blocking SnackBar when the worker
// reconciles a 409. Wraps any screen that wants to react to remote
// status overrides — currently the booking detail screen.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Outbox Worker Extensions". Validates Requirement 3.11.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bookings/application/booking_providers.dart';
import '../../features/bookings/domain/status_repository.dart';
import '../../theme/app_colors.dart';

class StatusConflictListener extends ConsumerWidget {
  const StatusConflictListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<
      AsyncValue<StatusConflictEvent>
    >(outboxStatusConflictStreamProvider, (prev, next) {
      next.whenData((event) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              content: Text(
                'Status changed remotely — kept the server value '
                '(${event.serverStatus.name}, you tried ${event.attemptedTo.name}).',
                style: TextStyle(color: AppColors.film),
              ),
              action: SnackBarAction(
                textColor: AppColors.orange,
                label: 'Dismiss',
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
            ),
          );
      });
    });
    return child;
  }
}
