// lib/features/public_booking/presentation/pending_public_bookings_screen.dart
//
// Owner / Both inbox of public-booking submissions awaiting decision.
// Streams the local Drift mirror, kicks a background `refreshPending`
// on first frame so the list reflects the server, and exposes per-row
// Approve / Reject actions.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` →
// "Public Booking Approval". Validates Requirements 6.6–6.10, 11.6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/booking_format.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../shared/states/offline_banner.dart';
import '../../../theme/app_colors.dart';
import '../../bookings/application/booking_providers.dart';
import '../application/public_booking_providers.dart';
import '../domain/public_booking_request.dart';
import '../../../theme/app_theme.dart';

class PendingPublicBookingsScreen extends ConsumerStatefulWidget {
  const PendingPublicBookingsScreen({super.key});

  @override
  ConsumerState<PendingPublicBookingsScreen> createState() =>
      _PendingPublicBookingsScreenState();
}

class _PendingPublicBookingsScreenState
    extends ConsumerState<PendingPublicBookingsScreen> {
  @override
  void initState() {
    super.initState();
    // Background-refresh on mount so the local mirror is fresh. We
    // deliberately don't await — the StreamProvider will pick up new
    // rows as they land.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures
      ref.read(publicBookingRepositoryProvider).refreshPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(bookingsPolicyProvider);
    final pendingAsync = ref.watch(pendingPublicBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        backgroundColor: AppColors.appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Pending requests',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: !policy.can(Capability.approvePublicBooking)
                  ? Center(
                      child: ErrorState(
                        message:
                            'You do not have permission to view this list.',
                        onRetry: () => Navigator.of(context).maybePop(),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.orange,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => ref
                          .read(publicBookingRepositoryProvider)
                          .refreshPending(),
                      child: pendingAsync.when(
                        loading: () =>
                            const _ScrollableSlot(child: LensLoader()),
                        error: (err, _) => _ScrollableSlot(
                          child: ErrorState(
                            message: 'Could not load pending requests.',
                            onRetry: () =>
                                ref.invalidate(pendingPublicBookingsProvider),
                          ),
                        ),
                        data: (rows) => rows.isEmpty
                            ? const _ScrollableSlot(
                                child: EmptyState(
                                  icon: Icons.inbox_outlined,
                                  message: 'No pending requests right now.',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  24,
                                ),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => _RequestRow(
                                  request: rows[i],
                                  onApprove: () => _onApprove(rows[i]),
                                  onReject: () => _onReject(rows[i]),
                                ),
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove(PublicBookingRequest req) async {
    try {
      final booking = await ref
          .read(publicBookingRepositoryProvider)
          .approve(req.id, policy: ref.read(bookingsPolicyProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approved · ${booking.title}')));
      // Drop into the new booking's detail screen so the user can
      // start filling in payment / assignments etc.
      Navigator.of(
        context,
      ).pushReplacementNamed(RouteNames.bookingDetail, arguments: booking.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _onReject(PublicBookingRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Reject request?',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'The request will be removed from the pending list.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(publicBookingRepositoryProvider)
          .reject(req.id, policy: ref.read(bookingsPolicyProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request rejected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    }
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final PublicBookingRequest request;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontFamily: AppText.monoFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${DateFormat.yMMMEd().format(request.date)} · '
            '${BookingFormat.clockRange(request.startTime, request.endTime, separator: '–')}',
            style: TextStyle(
              color: AppColors.filmDim,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: AppColors.filmMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${request.clientName} · ${request.clientPhone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.film, fontSize: 12.5),
                ),
              ),
            ],
          ),
          if ((request.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.film.withValues(alpha: 0.85),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.red,
                    size: 16,
                  ),
                  label: Text(
                    'Reject',
                    style: TextStyle(color: AppColors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.red.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onReject(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onApprove(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollableSlot extends StatelessWidget {
  const _ScrollableSlot({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(child: child),
        ),
      ],
    );
  }
}
